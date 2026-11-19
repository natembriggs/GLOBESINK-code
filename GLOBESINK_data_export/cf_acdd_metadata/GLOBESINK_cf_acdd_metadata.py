"""CF-1.8 and ACDD-1.3 metadata for the GLOBESINK NetCDF products.

Two modes, one set of attribute definitions:

  --mode upgrade (default)  Upgrade the published v1.0 files to v1.1 (described below).
  --mode export             Apply the same metadata to files freshly written by the MATLAB
                            export (GLOBESINK_netcdf_file_creation.m calls this as its last
                            step), so every later version inherits it. Values are copied
                            unchanged and verified; --product-version, --coverage-end and the
                            DOI/version options describe the new release.


v1.1 is a metadata-only release: every gridded value is copied verbatim from v1.0, so all
numbers, figures and validations in the data paper stand. What changes is metadata only:

  * ACDD-1.3 global attributes (title, summary, keywords, creator, licence, coverage, ...).
  * A CF climatological ``time`` coordinate with ``climatology_bounds``, replacing ``month``
    as the T axis; ``month`` (1-12) is kept as an auxiliary coordinate.
  * Cell bounds for the uneven depth bins and for the latitude and longitude cells.
  * ``standard_name`` where a CF name genuinely applies (CF table v94), UDUNITS-parsable
    ``units``, ``coverage_content_type``, ``cell_methods``, loose ``valid_min``/``valid_max``,
    and ``ancillary_variables`` linking each variable to n_bbp and its uncertainty fields.
  * A ``cell_status`` flag in the interpolated file saying which cells are observed,
    interpolated, or observed-but-replaced because the cell held fewer than min_n = 10
    backscattering measurements.
  * A scalar ``radiation_wavelength`` coordinate (700 nm) for the backscattering variables.
  * Single-precision scalar parameters (v1.0 stored the 22 flux parameters as double).
  * A provenance ``history`` naming this upgrade.

Usage
-----
    python GLOBESINK_cf_acdd_metadata.py --src <v1.0 dir> --out <v1.1 dir>
    python GLOBESINK_cf_acdd_metadata.py --src <v1.0 dir> --report
    python GLOBESINK_cf_acdd_metadata.py --src <v1.0 dir> --out <dir> --verify-only
    python GLOBESINK_cf_acdd_metadata.py --mode export --src <exported dir> --out <dir> \
        --product-version 2.0 --coverage-end 2026-09-30 --compress

``--report`` writes no files: it prints the data-quality diagnostics (non-finite values,
extreme values, all-missing variables) that the metadata cannot fix.

Writing is refused while placeholder metadata (an unminted DOI, a missing ORCID) is still
present unless ``--allow-placeholders`` is passed, so a release cannot go out with "TBD" in it.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import sys
from pathlib import Path

import netCDF4 as nc
import numpy as np

RAW_FILE = "GLOBESINK_monthly_climatologies.nc"
INTERP_FILE = "GLOBESINK_monthly_climatologies_smoothed_interpolated.nc"

MODE = "upgrade"  # or "export"; set from the command line
PRODUCT_VERSION = "1.1"
DATE_CREATED = "2026-05-13T14:07:53Z"  # creation time of the v1.0 files; "now" in export mode
MIN_N = 10  # bins with fewer bbp measurements are dropped before smoothing (paper, Sect. 2)
REFERENCE_EPOCH = "2010-01-01"
COVERAGE_START = dt.date(2010, 1, 1)
COVERAGE_END = dt.date(2025, 5, 31)
WAVELENGTH_NM = 700.0

# Depth bin edges, from the paper's gridding section: 0, 10, every 50 m from 50 to 900,
# 1000, every 200 m from 1200 to 1800, 2100. Verified against the published depth centres.
DEPTH_EDGES = np.array(
    [0.0, 10.0, *range(50, 901, 50), 1000.0, 1200.0, 1400.0, 1600.0, 1800.0, 2100.0], dtype="f8"
)
LAT_CELL = 4.0
LON_CELL = 8.0

# ---------------------------------------------------------------------------
# Metadata that must be filled in before the release goes out.
# ---------------------------------------------------------------------------
PLACEHOLDER = "TBD"
V10_DOI = "10.5281/zenodo.19558504"  # the published v1.0 files
DATASET_DOI = PLACEHOLDER  # this version's DOI (reserve it on the Zenodo draft); --dataset-doi
CONCEPT_DOI = "10.5281/zenodo.19558503"
PAPER_DOI = PLACEHOLDER  # ESSD paper DOI, once accepted
CODE_DOI = PLACEHOLDER  # Zenodo snapshot of the MATLAB repository (task D2)
CODE_URL = "https://github.com/natembriggs/GLOBESINK-code"
CODE_VERSION = PLACEHOLDER  # git tag of the published version (task D2)
CREATOR_ORCID = "https://orcid.org/0000-0003-1549-1386"
ARGO_GDAC_DOI = "10.17882/42182"
NOC_ROR = "https://ror.org/00874hx02"
NOC_NAME = "National Oceanography Centre"
CONTRIBUTORS = (  # name, email (from GLOBESINK_author_list.csv); all at NOC
    ("Stephanie Henson", "s.henson@noc.ac.uk"),
    ("Anita Flohr", "anita.flohr@noc.ac.uk"),
    ("Hans Hilder", "Hans.Hilder@noc.ac.uk"),
)
# NERC Vocabulary Server terms (checked 11 Nov 2026): L06 platform category 46, and L05 device
# categories 123 (optical backscatter sensors), 130 (CTD), 113 (fluorometers), 351 (dissolved gas
# sensors), 181 (nutrient analysers), 355 (pH sensors).
PLATFORM = "drifting subsurface profiling float"
INSTRUMENTS = (
    "optical backscatter sensors", "CTD", "fluorometers", "dissolved gas sensors",
    "nutrient analysers", "pH sensors",
)
# Processing parameters of the published run, recorded as global attributes (AC D-6).
PROCESSING_PARAMETERS = {
    "processing_spike_size_classes": (
        "bbp spikes are assigned to particle size classes by height: 203, 406 and 812 micrometre "
        "equivalent spherical diameter correspond to spike heights of 0.78, 3.1 and 12.4 x 10-4 m-1, "
        "assuming backscattering efficiency Qbb = 0.024 and sample volume Vbb = 10 ml"
    ),
    "processing_range_test": (
        "raw measurements removed where the filtered backscattering exceeded 0.03 m-1 at any depth, "
        "0.004 m-1 below 200 m or 0.002 m-1 below 500 m"
    ),
    "processing_deep_alignment": (
        "additive per-float offset aligning deep (below 450 m) bbp with nearby floats within a "
        "2000 km search radius, same calendar month, any year"
    ),
    "processing_min_measurements": (
        "cells with fewer than 10 bbp measurements were removed before smoothing; the flux "
        "validation uses cells with more than 100"
    ),
    "processing_depth_bin_edges_m": "0, 10, 50 to 900 every 50, 1000, 1200 to 1800 every 200, 2100",
    "processing_conversion_parameters": "see the scalar variables in this file (POC_bbp_ratio, w_s, w_m, w_l and the depth-correction exponents)",
}
PROCESSING_STAGES = (
    "Argo GDAC download and S-file merge; automated bbp and CDOM quality control (range test, "
    "local outlier and spike tests, near-bottom removal); grey list and visual quality control; "
    "per-cast depth binning with spike/baseline size fractionation; monthly per-float binning; "
    "deep inter-float alignment; monthly 4 x 8 degree climatology; POC and POC flux with propagated "
    "uncertainties; spatial smoothing and gap filling (smoothed file); NetCDF export"
)
# >800 um flux term (RC2 point 3), from the analysis re-run on the v1.0 file on 11 Nov 2026
# (First_revision/validation/bbx_flux_v10_2026-11-11): mean-preserving power law through binned
# arithmetic means of bbx against bbl in cells with n_bbp >= 1600, and the size scaling of sinking
# speed w ~ d^eta with eta = 0.63 from the product's own w_m and w_l, for particles twice the
# diameter of those in bbl.
BBX_FIT_INTERCEPT = -1.1315511498395479
BBX_FIT_SLOPE = 0.7422456764510272
BBX_SINKING_FACTOR = 2.0**0.63  # w_x / w_l
# The term is folded, in quadrature, into this existing field (raw file only; the smoothed file
# carries no uncertainty fields). No new variable is added (Nathan, 11 Nov 2026).
BBX_UPPER_VAR = "flux_POC_systematic_uncertainty_upper"
BBX_UPPER_LONG_NAME = (
    "upper additive systematic uncertainty of flux_POC, including an estimate of the unresolved "
    "flux of particles >800 µm"
)
BBX_UPPER_NOTE = (
    "v{version} change: this upper uncertainty now also includes, combined in quadrature with the "
    "conversion-parameter term, an estimate F_x of the sinking POC flux carried by particles larger "
    "than 800 µm, which flux_POC does not include. bbx cannot be used directly because cells with "
    "few measurements rarely sample a >800 µm particle, so it is predicted from bbl with a "
    "mean-preserving power law fitted in well-sampled cells (n_bbp >= 1600): "
    "bbx = 10^({a:.4f}) * bbl^{b:.4f}. Then F_x = flux_POCl * (bbx/bbl) * w_x/w_l, which assumes "
    "the product's POC/bbp conversion and particles twice the diameter of those in bbl, sinking with "
    "the product's size scaling of sinking speed (w_x/w_l = 2^0.63 = {w:.4f}). Under these "
    "assumptions F_x is about 59 % of flux_POC globally and 55 % to 76 % by depth; an assumed "
    "diameter of 1.5 or 3 times that of bbl gives about 50 % or 75 %. It is a sensitivity estimate "
    "for an open-ended size class, not a physical bound: larger particles would raise it, and "
    "backscattering by swimming animals counted in bbx would lower it. The lower uncertainty is "
    "unchanged, because omitting a flux cannot make the true flux smaller. {n} cells changed; the "
    "v1.0 value is sqrt(value^2 - F_x^2), with F_x computed from bbl and flux_POCl in this file. "
    "See the accompanying paper (response to referee 2, point 3)."
)
LOW_PRECISION_N = 100  # the validation threshold; cells with n_bbp <= this are flagged in the raw file

ACKNOWLEDGEMENT = (
    "This work was supported by the UK Natural Environment Research Council (NERC) GLOBESINK "
    "project (NE/X008657/1), the European Union Horizon 2020 project TechOceans (Grant Agreement "
    "No. 101000858), the NERC National Capability Single Centre Science Programme AtlantiS "
    "(NE/Y005589/1), and the European Union under grant agreements no. 101216427 (BioGeoSea) and "
    "no. 101083922 (OceanICU) and UK Research and Innovation (UKRI) under the UK government's "
    "Horizon Europe funding guarantee (grant numbers 10054454, 10063673, 10064020, 10059241, "
    "10079684, 10059012, 10048179). Argo data were collected and made freely available by the "
    "International Argo Program and the national programmes that contribute to it "
    "(https://argo.ucsd.edu, https://biogeochemical-argo.org). This is a value-added research "
    "product derived from those observations; it is not an official Argo product and has not been "
    "reviewed or endorsed by the Argo programme."
)

SUMMARY = (
    "Global gridded monthly climatology of size-fractionated particle optical backscattering, "
    "particulate organic carbon (POC) concentration, sinking POC flux, area-weighted mean "
    "particle diameter and particle number concentration in three size classes, derived from "
    "Biogeochemical-Argo float profiles collected between {coverage} by the "
    "'optical backscattering spikes' particle size fractionation method. Backscattering is "
    "partitioned into particle size classes spanning roughly 1 to 800 micrometres. Each carbon "
    "concentration and flux estimate carries an additive precision uncertainty, from the random "
    "encounter of rare large particles, and an additive systematic uncertainty propagated from "
    "the empirical conversion parameters. Climatologies of temperature, salinity, nitrate, pH, "
    "oxygen and chlorophyll a from the same floats are included for reference only. The grid is "
    "4 degrees latitude by 8 degrees longitude, over 25 depth bins between 0 and 2000 m, with "
    "vertical resolution from 10 m near the surface to 300 m at depth."
)

KEYWORDS = (
    "GCMDSK:EARTH SCIENCE > OCEANS > OCEAN CHEMISTRY > ORGANIC CARBON, "
    "GCMDSK:EARTH SCIENCE > OCEANS > OCEAN OPTICS > SCATTERING, "
    "GCMDSK:EARTH SCIENCE > OCEANS > OCEAN CHEMISTRY > CARBON, "
    "GCMDSK:EARTH SCIENCE > OCEANS > MARINE SEDIMENTS > SEDIMENT TRANSPORT, "
    "GCMDSK:EARTH SCIENCE > OCEANS > OCEAN TEMPERATURE, "
    "GCMDSK:EARTH SCIENCE > OCEANS > SALINITY/DENSITY > SALINITY"
)
KEYWORDS_VOCABULARY = (
    "GCMDSK:GCMD Science Keywords:https://gcmd.earthdata.nasa.gov/kms/concepts/concept_scheme/sciencekeywords"
)

# ---------------------------------------------------------------------------
# Per-variable metadata
# ---------------------------------------------------------------------------
# CF standard names, checked against CF standard name table v94. Variables absent from this
# table have no suitable CF name and keep a descriptive long_name plus a comment instead.
STANDARD_NAMES = {
    "POCs": "mass_concentration_of_particulate_organic_matter_expressed_as_carbon_in_sea_water",
    "POCm": "mass_concentration_of_particulate_organic_matter_expressed_as_carbon_in_sea_water",
    "POCl": "mass_concentration_of_particulate_organic_matter_expressed_as_carbon_in_sea_water",
    "TEMP": "sea_water_temperature",
    "TEMP_ADJUSTED": "sea_water_temperature",
    "PSAL_ADJUSTED": "sea_water_practical_salinity",
    "PRES": "sea_water_pressure",
    "CHLA_ADJUSTED": "mass_concentration_of_chlorophyll_a_in_sea_water",
    "DOXY_ADJUSTED": "moles_of_oxygen_per_unit_mass_in_sea_water",
    "NITRATE_ADJUSTED": "mole_concentration_of_nitrate_in_sea_water",
    "PH_IN_SITU_TOTAL_ADJUSTED": "sea_water_ph_reported_on_total_scale",
    "depth": "depth",
    "lat": "latitude",
    "lon": "longitude",
    "time": "time",
    "radiation_wavelength": "radiation_wavelength",
}

# v1.0 units string -> UDUNITS-parsable equivalent. "mg C m^-3" becomes "mg m-3": UDUNITS reads
# the C in the old string as coulombs, so "of carbon" belongs in long_name, not in units.
UNITS_MAP = {
    "m^-1": "m-1",
    "m^-2": "m-2",
    "m^-^1": "m-1",
    "mg C m^-3": "mg m-3",
    "mg C m^-2 d^-1": "mg m-2 d-1",
    "mg m^-3": "mg m-3",
    "m d^-^1": "m d-1",
    "µm": "1e-6 m",
    "L^-1": "L-1",
    "db": "dbar",
    "°C": "degree_C",
    "µmol kg^-1": "umol kg-1",
    "mmol m^-3": "mmol m-3",
    "-": "1",
    "1": "1",
    "m": "m",
    "degrees_north": "degrees_north",
    "degrees_east": "degrees_east",
}

# Typos in v1.0 long_name attributes (the MATLAB lookup spreadsheet is corrected to match).
LONG_NAME_FIXES = {
    "bbr": "optical backscattering background attributed to refractory particles",
    "mean_depth": "mean depth of measurements within depth bin",
}
VARIABLE_SUMMARY_XLSX = "GLOBESINK_netcdf_variable_summary.xlsx"

# Units that are wrong in v1.0, not merely non-UDUNITS. POC_bbp_ratio converts bbp (m-1) to POC
# (mg m-3), so it is mg m-2; v1.0 labels it "mg m^-^2 d^-^1". Needs Nathan's sign-off: listed by
# --report and announced on every run.
UNITS_CORRECTIONS = {
    "POC_bbp_ratio": ("mg m^-^2 d^-^1", "mg m-2"),
    "POC_bbp_ratio_upper": ("mg m^-^2 d^-^1", "mg m-2"),
    "POC_bbp_ratio_lower": ("mg m^-^2 d^-^1", "mg m-2"),
}

BBP_VARS = ("bbr", "bbs", "bbm", "bbl", "bbx", "bbs_med", "bbml_med", "var_bbml")
DERIVED_VARS = (
    "POCs",
    "POCm",
    "POCl",
    "flux_POCs",
    "flux_POCm",
    "flux_POCl",
    "flux_POC",
    "D_mean",
    "C_200_400",
    "C_400_800",
    "C_800",
)
REFERENCE_VARS = (
    "PRES",
    "TEMP",
    "TEMP_ADJUSTED",
    "PSAL_ADJUSTED",
    "CHLA_ADJUSTED",
    "DOXY_ADJUSTED",
    "NITRATE_ADJUSTED",
    "PH_IN_SITU_TOTAL_ADJUSTED",
)
AUX_VARS = ("n_bbp", "mean_depth")
COORD_VARS = ("depth", "lat", "lon", "month", "time")

# Loose physical limits, every one checked against the actual v1.0 data range before it is
# written (netCDF4-python masks values outside valid_min/valid_max on read, so a limit that
# clipped real data would silently hide it). A variable absent here gets no valid range.
VALID_RANGE = {
    "bbr": (0.0, None),
    "bbs_med": (0.0, None),
    "n_bbp": (0.0, None),
    "POCs": (0.0, None),
    "POCm": (0.0, None),
    "POCl": (0.0, None),
    "flux_POCs": (0.0, None),
    "flux_POCm": (0.0, None),
    "flux_POCl": (0.0, None),
    "flux_POC": (0.0, None),
    "C_200_400": (0.0, None),
    "C_400_800": (0.0, None),
    "C_800": (0.0, None),
    "D_mean": (0.0, None),
    "PRES": (0.0, 2200.0),
    "TEMP_ADJUSTED": (-2.5, 40.0),
    "PSAL_ADJUSTED": (0.0, 45.0),
    "PH_IN_SITU_TOTAL_ADJUSTED": (7.0, 9.0),
    "depth": (0.0, 2100.0),
    "lat": (-90.0, 90.0),
    "lon": (-180.0, 180.0),
}

QC_NOTE = (
    " Before gridding, individual measurements were removed by a depth-dependent range test "
    "(filtered backscattering above 0.03 m-1 at any depth, 0.004 m-1 below 200 m or 0.002 m-1 "
    "below 500 m) and by spike and outlier tests; those thresholds apply to raw measurements, not to "
    "these gridded means, and are not valid ranges for them."
)
NO_CF_BBP = (
    " No CF standard name exists for size-fractionated particulate backscattering: the CF name "
    "volume_backwards_scattering_coefficient_of_radiative_flux_in_sea_water denotes total "
    "backscattering by sea water, not a particulate size fraction, so it is deliberately not used here."
)

COMMENTS = {
    "bbr": (
        "Time- and depth-invariant background backscattering attributed to small refractory "
        "particles, estimated per grid cell as the minimum smoothed, interpolated climatological "
        "bbrs across all depths and months. Spatial patterns include both real variability in "
        "refractory particle concentration and any systematic regional sensor calibration offset."
    ) + NO_CF_BBP,
    "n_bbp": (
        "Number of individual backscattering measurements contributing to the cell. Large-particle "
        f"quantities have low precision where this is small; cells with fewer than {MIN_N} "
        "measurements were excluded before the smoothing and interpolation step that produced the "
        "companion smoothed, interpolated climatology."
    ),
    "mean_depth": (
        "All values are missing in v1.0 of this dataset: the field was written but never "
        "populated. Retained for structural continuity with v1.0 and populated in a future version."
    ),
    "bbx": (
        "Particulate backscattering at 700 nm attributed to particles larger than 800 micrometres "
        "by the optical backscattering spikes method; not included in any POC or flux variable. "
        "Each measurement samples about 10 ml, so most cells with few measurements detect no "
        "particle in this class, and where one is detected the cell value is inflated; treat "
        "cells with few measurements (see n_bbp) with caution. No CF standard name exists for "
        "size-fractionated particulate backscattering."
    ) + QC_NOTE,
    "D_mean": (
        "Area-weighted mean equivalent spherical diameter of particles smaller than 800 micrometres. "
        "Includes detrital particles such as aggregates and faecal pellets, so it is not an index "
        "of plankton size. Not independently validated."
    ),
}

BASELINE_COMMENT = (
    "Particulate backscattering at 700 nm attributed to small particles (below about 200 "
    "micrometres): the baseline of each backscattering profile once spikes from individual large "
    "particles are removed, less the refractory background bbr."
) + NO_CF_BBP + QC_NOTE
BASELINE_MED_COMMENT = (
    "Particulate backscattering at 700 nm attributed to small particles, estimated with a 5-point "
    "running median of each profile; used, with bbml_med, to compute the mean particle diameter D_mean."
) + NO_CF_BBP + QC_NOTE
MED_RESIDUAL_COMMENT = (
    "Derived from the residual of each backscattering profile about a 5-point running median, i.e. "
    "the signal of particles larger than about 200 micrometres; used to compute D_mean."
) + NO_CF_BBP + QC_NOTE
BBP_COMMENT = (
    "Particulate backscattering at 700 nm attributed to one particle size class by the optical "
    "backscattering spikes method. No CF standard name exists for size-fractionated particulate "
    "backscattering: the CF name volume_backwards_scattering_coefficient_of_radiative_flux_in_"
    "sea_water denotes total backscattering by sea water, not a particulate size fraction, so it "
    "is deliberately not used here."
) + QC_NOTE
FLUX_COMMENT = (
    "Sinking flux of particulate organic carbon, in mass units. No CF standard name exists for "
    "sinking POC flux in mass units; the equivalent molar quantity is "
    "sinking_mole_flux_of_particulate_organic_matter_expressed_as_carbon_in_sea_water, reached by "
    "dividing by 12011 mg mol-1 and by 86400 s d-1. Mass units are retained because every "
    "sediment-trap and thorium-234 dataset this product is validated against uses them."
)
POC_COMMENT = (
    "Particulate organic carbon concentration derived from particulate backscattering through an "
    "empirical, depth-dependent conversion; see the scalar conversion parameters in this file."
)
COUNT_COMMENT = (
    "Number concentration of particles in this size class, derived from particulate backscattering. "
    "No CF standard name exists for particle number concentration by size class. Not independently "
    "validated."
)
PRECISION_COMMENT = (
    "Additive {bound} bound of the 95 % one-sided confidence interval on {parent}, from the random "
    "encounter of rare large particles (Poisson sampling). Add to {parent} to obtain the bound."
)
SYSTEMATIC_COMMENT = (
    "Additive {bound} systematic uncertainty of {parent}, propagated in quadrature from the bounds "
    "of the empirical conversion parameters. Add to {parent} to obtain the bound."
)
REFERENCE_COMMENT = (
    "Reference climatology, gridded in the same way as the backscattering products from the same "
    "float profiles. Suitable only as context for the POC and flux fields in this file: it is "
    "derived solely from floats carrying a backscattering sensor, not from the full Argo array, "
    "and has no quality assurance beyond the standard Argo adjustment and flagging."
)
SCALAR_COMMENT = (
    "Scalar parameter of the backscattering-to-carbon and flux conversions, identical for every "
    "grid cell. The _upper and _lower counterparts bound the sensitivity analysis from which the "
    "systematic uncertainty fields are propagated; they are parameter bounds, not cell extents."
)
CELL_METHODS_RAW = (
    "time: mean within years time: mean over years "
    "(spatial cell value is the mean over the 4 degree latitude by 8 degree longitude by depth "
    "bin cell, weighted by the number of measurements)"
)
# CF 7.4 requires the cell_methods of a variable on a climatological time axis to be the
# climatology form; the spatial aggregation therefore goes in the parenthetical comment, not as
# "lat: lon: depth: mean". The 3x3 median filter and gap-filling of the smoothed product are
# described in the file comment and in the cell_status flag instead.
CELL_METHODS_INTERP = CELL_METHODS_RAW
INTERP_FILE_COMMENT = (
    "Smoothed, gap-filled counterpart of the raw climatology. Cells holding fewer than "
    f"{MIN_N} backscattering measurements were removed, a 3x3 grid-cell moving median was applied "
    "for each month and depth (medians of windows holding fewer than 3 values were removed), and "
    "remaining gaps were filled by linear interpolation between cells, except in the Arctic and "
    "regions of near-permanent sea ice around Antarctica. See the cell_status flag for which "
    "cells are observed and which are interpolated."
)


def coverage_content_type(name: str) -> str:
    """ACDD coverage_content_type for one variable."""
    if name in COORD_VARS or name.endswith("_bnds") or name == "radiation_wavelength":
        return "coordinate"
    if "_precision_" in name or "_systematic_uncertainty_" in name or name == "cell_status":
        return "qualityInformation"
    if name in BBP_VARS or name in REFERENCE_VARS:
        return "physicalMeasurement"
    if name in DERIVED_VARS:
        return "modelResult"
    return "auxiliaryInformation"


def variable_comment(name: str) -> str | None:
    """The comment for one variable, by name or by naming convention."""
    if name == "mean_depth" and MODE == "export":
        return "Mean depth of the measurements contributing to the cell."
    if name in COMMENTS:
        return COMMENTS[name]
    for suffix, template in (
        ("_precision_upper", PRECISION_COMMENT),
        ("_precision_lower", PRECISION_COMMENT),
        ("_systematic_uncertainty_upper", SYSTEMATIC_COMMENT),
        ("_systematic_uncertainty_lower", SYSTEMATIC_COMMENT),
    ):
        if name.endswith(suffix):
            parent = name[: -len(suffix)]
            bound = "upper" if name.endswith("upper") else "lower"
            return template.format(bound=bound, parent=parent)
    if name == "bbs":
        return BASELINE_COMMENT
    if name == "bbs_med":
        return BASELINE_MED_COMMENT
    if name in ("bbml_med", "var_bbml"):
        return MED_RESIDUAL_COMMENT
    if name in BBP_VARS:
        return BBP_COMMENT
    if name.startswith("flux_POC"):
        return FLUX_COMMENT
    if name in ("POCs", "POCm", "POCl"):
        return POC_COMMENT
    if name.startswith("C_"):
        return COUNT_COMMENT
    if name in REFERENCE_VARS:
        return REFERENCE_COMMENT
    return None


def ancillary_variables(name: str, present: set[str]) -> str | None:
    """Link a base variable to n_bbp and to its uncertainty fields, by naming convention."""
    if name in COORD_VARS or name.endswith("_bnds") or name in ("cell_status", "low_precision_flag"):
        return None
    if "_precision_" in name or "_systematic_uncertainty_" in name:
        return None
    # scalar conversion parameters: link the base value to its sensitivity-analysis bounds (AC D-5)
    bounds = [f"{name}{b}" for b in ("_lower", "_upper") if f"{name}{b}" in present]
    if bounds:
        return " ".join(bounds)
    linked = [
        f"{name}{suffix}"
        for suffix in (
            "_precision_lower",
            "_precision_upper",
            "_systematic_uncertainty_lower",
            "_systematic_uncertainty_upper",
        )
        if f"{name}{suffix}" in present
    ]
    if name in BBP_VARS or name in DERIVED_VARS:
        linked.insert(0, "n_bbp")
    if name == "n_bbp" or not linked:
        return None
    return " ".join(linked)


def build_time_axis() -> tuple[np.ndarray, np.ndarray]:
    """CF climatological time: one value per climatological month, with climatology bounds.

    The coordinate value is the midpoint of the month's first occurrence (January 2010). The
    bounds span the first occurrence's start to the last occurrence's end, which differs by
    month because the record ends on 31 May 2025.
    """
    epoch = dt.date.fromisoformat(REFERENCE_EPOCH)
    values = np.empty(12, dtype="f8")
    bounds = np.empty((12, 2), dtype="f8")
    for i, month in enumerate(range(1, 13)):
        first_start = dt.date(COVERAGE_START.year, month, 1)
        next_month = dt.date(first_start.year + (month == 12), month % 12 + 1, 1)
        values[i] = (first_start - epoch).days + (next_month - first_start).days / 2.0
        last_year = COVERAGE_END.year if month <= COVERAGE_END.month else COVERAGE_END.year - 1
        last_start = dt.date(last_year, month, 1)
        last_end = dt.date(last_start.year + (month == 12), month % 12 + 1, 1)
        bounds[i, 0] = (first_start - epoch).days
        bounds[i, 1] = (last_end - epoch).days
    return values, bounds


def _coverage_words() -> str:
    return f"{COVERAGE_START.strftime('%B %Y')} and {COVERAGE_END.strftime('%B %Y')}"


def _coverage_duration() -> str:
    """ISO 8601 duration of the whole months from COVERAGE_START to COVERAGE_END."""
    months = (COVERAGE_END.year - COVERAGE_START.year) * 12 + COVERAGE_END.month - COVERAGE_START.month + 1
    years, rest = divmod(months, 12)
    return f"P{years}Y{rest}M" if rest else f"P{years}Y"


def cell_bounds(centres: np.ndarray, width: float) -> np.ndarray:
    """Bounds for regularly spaced cell centres."""
    out = np.empty((centres.size, 2), dtype="f8")
    out[:, 0] = centres - width / 2.0
    out[:, 1] = centres + width / 2.0
    return out


def placeholders_present() -> list[str]:
    """Metadata still carrying the placeholder value."""
    names = {
        "paper DOI": PAPER_DOI,
        "code DOI": CODE_DOI,
        "code version tag": CODE_VERSION,
        "creator ORCID": CREATOR_ORCID,
        "dataset DOI": DATASET_DOI,
    }
    return [label for label, value in names.items() if value == PLACEHOLDER]


def global_attributes(*, role: str, src_history: str, upgraded: str) -> dict[str, str | float]:
    """ACDD-1.3 global attributes for one file."""
    title = {
        "raw": "GLOBESINK monthly climatology of size-fractionated particle backscattering, POC and sinking POC flux from BGC-Argo",
        "interp": "GLOBESINK monthly climatology of size-fractionated particle backscattering, POC and sinking POC flux from BGC-Argo (smoothed and gap-filled)",
    }[role]
    summary = SUMMARY.format(coverage=_coverage_words())
    summary = summary if role == "raw" else summary + " " + INTERP_FILE_COMMENT
    history = (
        f"{src_history}\n{upgraded} : metadata upgraded to v{PRODUCT_VERSION} "
        "(CF-1.8 and ACDD-1.3) by GLOBESINK_data_export/cf_acdd_metadata/GLOBESINK_cf_acdd_metadata.py in "
        f"{CODE_URL}; gridded values copied from v1.0 and verified identical apart from any corrections recorded below"
    )
    if MODE == "export":
        history = (
            f"{src_history}\n{upgraded} : CF-1.8 and ACDD-1.3 metadata applied by "
            f"GLOBESINK_data_export/cf_acdd_metadata/GLOBESINK_cf_acdd_metadata.py in {CODE_URL} at "
            f"version {CODE_VERSION}; gridded values copied unchanged from the MATLAB export and verified"
        )
    if PROCESSING_STAGES not in history:
        history = f"Processing stages before file creation (dates not recorded): {PROCESSING_STAGES}\n{history}"
    n = len(CONTRIBUTORS)
    attrs: dict[str, str | float] = {
        "Conventions": "CF-1.8, ACDD-1.3",
        "title": title,
        "summary": summary,
        "keywords": KEYWORDS,
        "keywords_vocabulary": KEYWORDS_VOCABULARY,
        "standard_name_vocabulary": "CF Standard Name Table v94",
        "id": DATASET_DOI,
        "naming_authority": "org.doi",
        "metadata_link": f"https://doi.org/{CONCEPT_DOI}",
        "license": "http://spdx.org/licenses/CC-BY-4.0 (CC-BY-4.0)",
        "product_version": PRODUCT_VERSION,
        "cdm_data_type": "Grid",
        "spatial_representation": "grid",
        "iso_topic_category": "oceans",
        "activity_type": "In Situ Ocean moving station",
        "operational_status": "Scientific",
        "quality_control": (
            "Automated range, spike and outlier tests, Argo grey list, visual quality control by two "
            "operators, and deep inter-float alignment; see the accompanying paper and the "
            "processing_* attributes"
        ),
        "processing_level": "Gridded climatology derived from quality-controlled BGC-Argo profiles",
        "institution": "National Oceanography Centre, Southampton, UK",
        "source": (
            "Biogeochemical-Argo profiling float observations obtained from the Coriolis Global "
            "Data Assembly Centre"
        ),
        # adc.met.no: one platform entry per instrument entry
        "platform": ", ".join([PLATFORM] * len(INSTRUMENTS)),
        "platform_vocabulary": "NVS L06 Platform Categories:https://vocab.nerc.ac.uk/collection/L06/current/",
        "instrument": ", ".join(INSTRUMENTS),
        "instrument_vocabulary": "NVS L05 SeaDataNet device categories:https://vocab.nerc.ac.uk/collection/L05/current/",
        "creator_name": "Nathan Briggs",
        "creator_email": "natbrig@noc.ac.uk",
        "creator_institution": NOC_NAME,
        "creator_institution_pid": NOC_ROR,
        "creator_type": "person",
        "creator_url": CREATOR_ORCID,
        "creator_pid": CREATOR_ORCID,
        "contributor_type": ", ".join(["person"] * n),
        "contributor_name": ", ".join(c[0] for c in CONTRIBUTORS),
        "contributor_role": ", ".join(["author"] * n),
        "contributor_email": ", ".join(c[1] for c in CONTRIBUTORS),
        "contributor_institution": ", ".join([NOC_NAME] * n),
        "contributor_institution_pid": ", ".join([NOC_ROR] * n),
        "publisher_name": "National Oceanography Centre",
        "publisher_institution": NOC_NAME,
        "publisher_institution_pid": NOC_ROR,
        "publisher_email": "natbrig@noc.ac.uk",
        "publisher_url": "https://noc.ac.uk",
        "publisher_type": "institution",
        "project": "GLOBESINK, AtlantiS",
        "program": "Biogeochemical-Argo",
        "acknowledgement": ACKNOWLEDGEMENT,
        # adc.met.no form: comma-separated "URL (type: description)", no commas inside
        "references": ", ".join(
            [
                f"https://doi.org/{PAPER_DOI} (Data paper: GLOBESINK data description paper in Earth System Science Data)",
                f"https://doi.org/{CODE_DOI} (Software: GLOBESINK processing code {CODE_VERSION})",
                f"https://doi.org/{ARGO_GDAC_DOI} (Other documentation: Argo float data and metadata from the Global Data Assembly Centre)",
            ]
        ),
        "source_code": f"{CODE_URL} at version {CODE_VERSION}",
        "software_version": CODE_VERSION,
        "dataset_doi": f"https://doi.org/{DATASET_DOI}",
        # Horizontal extents, like the vertical ones, are the coordinate variables' own range
        # (cell centres); the cells span the whole globe, as geospatial_bounds and the bounds
        # variables record.
        "geospatial_lat_min": -88.0,
        "geospatial_lat_max": 88.0,
        "geospatial_lat_units": "degrees_north",
        "geospatial_lat_resolution": (
            f"{LAT_CELL} degrees; cell centres from -88 to 88 degrees_north span cell edges from "
            "-90 to 90 (see lat_bnds)"
        ),
        "geospatial_lon_min": -176.0,
        "geospatial_lon_max": 176.0,
        "geospatial_lon_units": "degrees_east",
        "geospatial_lon_resolution": (
            f"{LON_CELL} degrees; cell centres from -176 to 176 degrees_east span cell edges from "
            "-180 to 180 (see lon_bnds)"
        ),
        # The vertical extents are the depth coordinate's own range (bin centres). The cells they
        # stand for span the full 0-2100 m of DEPTH_EDGES, which depth_bnds carries.
        "geospatial_vertical_min": 5.0,
        "geospatial_vertical_max": 1950.0,
        "geospatial_vertical_units": "m",
        "geospatial_vertical_positive": "down",
        "geospatial_vertical_resolution": (
            "uneven depth bins, 10 m near the surface to 300 m at depth; bin centres from 5 to "
            f"1950 m span cell edges from {DEPTH_EDGES[0]:.0f} to {DEPTH_EDGES[-1]:.0f} m "
            "(see depth_bnds)"
        ),
        "geospatial_bounds": "POLYGON ((-180 -90, -180 90, 180 90, 180 -90, -180 -90))",
        "geospatial_bounds_crs": "EPSG:4326",
        "geospatial_bounds_vertical_crs": "EPSG:5831",
        "time_coverage_start": f"{COVERAGE_START.isoformat()}T00:00:00Z",
        "time_coverage_end": f"{COVERAGE_END.isoformat()}T23:59:59Z",
        "time_coverage_duration": _coverage_duration(),
        "time_coverage_resolution": "P1M",
        "date_created": upgraded if MODE == "export" else DATE_CREATED,
        "date_modified": upgraded,
        "date_issued": upgraded,
        "comment": (
            "Produced by the GLOBESINK MATLAB pipeline; the code version is in source_code and "
            "the processing steps are in history. "
            if MODE == "export"
            else "Metadata upgrade of v1.0: every gridded value is identical to v1.0 "
            f"(https://doi.org/{V10_DOI}) apart from the corrections recorded in history. "
        )
        + "The source_variable_name attribute gives the name of each field in the processing code; "
        "it is provenance only and is not needed to interpret the data. "
        + (INTERP_FILE_COMMENT if role == "interp" else ""),
        "history": history,
        **PROCESSING_PARAMETERS,
    }
    attrs["comment"] = attrs["comment"].strip()
    return attrs


def _units_for(name: str, src_units: str | None) -> str | None:
    if src_units is None:
        return None
    if name in UNITS_CORRECTIONS:
        old, new = UNITS_CORRECTIONS[name]
        if src_units == old:
            return new
    if src_units in UNITS_MAP:
        return UNITS_MAP[src_units]
    return src_units


def _check_valid_range(name: str, data: np.ndarray, fill: float | None) -> tuple[float | None, float | None]:
    """The valid range for a variable. Either limit is dropped if it would clip real data.

    netCDF4-python masks values outside valid_min/valid_max on read, so a limit tighter than
    the data would silently hide published values.
    """
    if name not in VALID_RANGE:
        return None, None
    low, high = VALID_RANGE[name]
    finite = data[np.isfinite(data)]
    if fill is not None:
        finite = finite[finite != fill]
    if finite.size:
        if low is not None and float(finite.min()) < low:
            print(f"  ! valid_min {low} would clip {name} (data min {finite.min():.6g}); skipped")
            low = None
        if high is not None and float(finite.max()) > high:
            print(f"  ! valid_max {high} would clip {name} (data max {finite.max():.6g}); skipped")
            high = None
    return low, high


def compute_cell_status(raw: nc.Dataset, interp: nc.Dataset) -> np.ndarray:
    """Flag which cells of the interpolated product are observed, replaced or interpolated.

    0 observed_smoothed            raw cell held at least min_n measurements
    2 observed_below_min_n_replaced raw cell held data but fewer than min_n measurements, so it
                                    was removed and refilled from its neighbours
    1 interpolated                 raw cell held no data
    -1 (fill)                      the interpolated product has no value here either
    """
    raw_flux = raw["flux_POC"][:]
    interp_flux = interp["flux_POC"][:]
    n_bbp = np.asarray(raw["n_bbp"][:])
    raw_valid = ~np.ma.getmaskarray(raw_flux)
    interp_valid = ~np.ma.getmaskarray(interp_flux)
    status = np.full(raw_valid.shape, -1, dtype="i1")
    status[interp_valid & ~raw_valid] = 1
    status[interp_valid & raw_valid & (n_bbp < MIN_N)] = 2
    status[interp_valid & raw_valid & (n_bbp >= MIN_N)] = 0
    return status


def bbx_flux_upper(src: nc.Dataset) -> tuple[np.ndarray, np.ndarray]:
    """flux_POC's upper systematic uncertainty with the >800 um term folded in, from v1.0 fields.

    Returns the new values (float64) and the mask of cells they replace: cells where the v1.0
    uncertainty is a real number and the >800 um term is positive. Other cells keep v1.0's value.
    """

    def arr(name: str) -> np.ndarray:
        a = np.asarray(src[name][...], dtype="f8")
        fv = getattr(src[name], "_FillValue", None)
        return np.where((a == fv) | ~np.isfinite(a), np.nan, a) if fv is not None else a

    bbl, flux_l, up_now = arr("bbl"), arr("flux_POCl"), arr(BBX_UPPER_VAR)
    with np.errstate(divide="ignore", invalid="ignore"):
        ratio = np.where(
            bbl > 0, 10 ** (BBX_FIT_INTERCEPT + BBX_FIT_SLOPE * np.log10(np.where(bbl > 0, bbl, 1))) / bbl, 0.0
        )
    ratio = np.where(np.isfinite(bbl), ratio, np.nan)
    flux_x = flux_l * ratio * BBX_SINKING_FACTOR
    up_new = np.sqrt(np.maximum(up_now, 0) ** 2 + flux_x**2)
    change = np.isfinite(up_now) & np.isfinite(flux_x) & (flux_x > 0)
    return up_new, change


def upgrade(
    src_path: Path,
    out_path: Path,
    *,
    role: str,
    raw_path: Path,
    compress: bool,
    mask_nonfinite: bool,
    bbx_mask: np.ndarray | None = None,
    offset_field: Path | None = None,
    bbx_flux_term: bool = False,
    temp_mask: np.ndarray | None = None,
) -> None:
    """Write the v1.1 file for one v1.0 file."""
    upgraded = dt.datetime.now(dt.UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
    print(f"\n{src_path.name} -> {out_path.name}")
    src = nc.Dataset(src_path)
    src.set_auto_mask(False)
    src.set_auto_scale(False)
    present = set(src.variables)
    time_values, time_bounds = build_time_axis()
    status = None
    if role == "interp":
        with nc.Dataset(raw_path) as raw, nc.Dataset(src_path) as interp:
            status = compute_cell_status(raw, interp)
        counts = {int(v): int((status == v).sum()) for v in (-1, 0, 1, 2)}
        print(
            f"  cell_status: observed {counts[0]}, interpolated {counts[1]}, "
            f"below-min-n replaced {counts[2]}, no data {counts[-1]}"
        )

    out = nc.Dataset(out_path, "w", format="NETCDF4_CLASSIC")
    out.createDimension("time", 12)
    for name in ("depth", "lat", "lon"):
        out.createDimension(name, len(src.dimensions[name]))
    out.createDimension("nv", 2)

    def dims_of(var: nc.Variable) -> tuple[str, ...]:
        return tuple("time" if d == "month" else d for d in var.dimensions)

    masked_counts: dict[str, int] = {}
    bbx_counts: dict[str, int] = {}
    temp_log: list[str] = []
    for name, var in src.variables.items():
        src_dtype = var.dtype
        dtype = "f4" if (var.ndim == 0 and src_dtype == np.float64) else src_dtype
        fill = getattr(var, "_FillValue", None)
        kwargs = {}
        if fill is not None:
            kwargs["fill_value"] = np.array(fill, dtype=dtype)
        if compress and var.ndim == 4:
            kwargs.update(zlib=True, complevel=4, shuffle=True)
        new = out.createVariable(name, dtype, dims_of(var), **kwargs)
        data = var[...]
        if mask_nonfinite and fill is not None and np.issubdtype(np.asarray(data).dtype, np.floating):
            data = np.asarray(data).copy()
            bad = ~np.isfinite(data)
            if bad.any():
                masked_counts[name] = int(bad.sum())
                data[bad] = fill
        if bbx_mask is not None and name in CORRUPT_BBX_VARS and fill is not None:
            data = np.asarray(data).copy()
            hit = bbx_mask & (data != fill)
            if hit.any():
                bbx_counts[name] = int(hit.sum())
                data[bbx_mask] = fill
        if temp_mask is not None and name == "TEMP" and fill is not None and temp_mask.any():
            data = np.asarray(data).copy()
            for im, ilon, ilat, iz in zip(*np.nonzero(temp_mask)):
                temp_log.append(
                    f"{float(data[im, ilon, ilat, iz]):.1f} degC in month {int(src['month'][im])}, "
                    f"lon {float(src['lon'][ilon]):g}, lat {float(src['lat'][ilat]):g}, depth {float(src['depth'][iz]):g} m"
                )
            data[temp_mask] = fill
        new[...] = np.asarray(data, dtype=dtype)

        for attr in var.ncattrs():
            if attr == "_FillValue":
                continue
            value = getattr(var, attr)
            if attr == "units":
                value = _units_for(name, value)
            if attr == "long_name":
                value = LONG_NAME_FIXES.get(name, value)
                value = value.replace(
                    "flux of particulate organic carbon concentration", "flux of particulate organic carbon"
                )
            if attr == "coordinates":
                continue  # rewritten below
            if attr == "axis" and name == "month":
                continue  # time now carries the T axis
            setattr(new, attr, value)

        if name in STANDARD_NAMES:
            new.standard_name = STANDARD_NAMES[name]
        new.coverage_content_type = coverage_content_type(name)
        comment = variable_comment(name)
        if name in UNITS_CORRECTIONS and getattr(var, "units", None) == UNITS_CORRECTIONS[name][0]:
            fixed = (
                f"The units of this parameter were given as '{UNITS_CORRECTIONS[name][0]}' in "
                f"v1.0; corrected to '{UNITS_CORRECTIONS[name][1]}' in v{PRODUCT_VERSION}. The "
                "value is unchanged."
            )
            comment = f"{comment} {fixed}" if comment else fixed
        if name in bbx_counts:
            fixed = (
                f"v{PRODUCT_VERSION} correction: {bbx_counts[name]} cells of this field were set to "
                "_FillValue because garbage BBP700 readings in the Argo files (values of 1 to 1e33 "
                "m-1, most already flagged 3 or 4 by the data centres, which v1.0 did not apply) had "
                "been counted as >800 micrometre particles there. Every such cell is listed, with "
                f"its v1.0 value, in {CORRUPT_BBX_CSV}. No other variable uses these fields."
            )
            comment = f"{comment} {fixed}" if comment else fixed
        if name == "TEMP" and temp_log:
            fixed = (
                f"v{PRODUCT_VERSION} correction: {len(temp_log)} cell(s) set to _FillValue because the "
                f"unadjusted temperature exceeded {TEMP_LIMIT:g} degC, a garbage reading (v1.0 value: "
                + "; ".join(temp_log)
                + "). TEMP_ADJUSTED in the same cell is unaffected."
            )
            comment = f"{comment} {fixed}" if comment else fixed
        if var.ndim == 0:
            comment = f"{SCALAR_COMMENT} {comment}" if comment else SCALAR_COMMENT
        if comment:
            new.comment = comment
        if var.ndim == 4:
            new.cell_methods = CELL_METHODS_RAW if role == "raw" else CELL_METHODS_INTERP
            coords = ["month"]
            if name in BBP_VARS or name.startswith(BBP_VARS):
                coords.append("radiation_wavelength")
            new.coordinates = " ".join(coords)
        linked = ancillary_variables(name, present)
        if linked:
            extra = ""
            if var.ndim == 4:
                extra = " cell_status" if role == "interp" else " low_precision_flag"
                if role == "raw" and name not in BBP_VARS and name not in DERIVED_VARS:
                    extra = ""
            new.ancillary_variables = linked + extra
        elif role == "interp" and var.ndim == 4 and name != "cell_status":
            new.ancillary_variables = "cell_status"
        low, high = _check_valid_range(name, np.asarray(var[...], dtype="f8"), fill)
        if low is not None:
            new.valid_min = np.array(low, dtype=dtype)
        if high is not None:
            new.valid_max = np.array(high, dtype=dtype)

    # New coordinate and bounds variables.
    tvar = out.createVariable("time", "f8", ("time",))
    tvar.standard_name = "time"
    tvar.long_name = "time of the climatological month"
    tvar.units = f"days since {REFERENCE_EPOCH} 00:00:00"
    tvar.calendar = "standard"
    tvar.axis = "T"
    tvar.climatology = "climatology_bounds"
    tvar.coverage_content_type = "coordinate"
    tvar.comment = (
        "Climatological monthly mean. The coordinate value is the midpoint of the month's first "
        "occurrence in the record; climatology_bounds spans the first to the last occurrence of "
        f"that month, which ends in {COVERAGE_END.strftime('%B %Y')}."
    )
    tvar[:] = time_values

    cbnds = out.createVariable("climatology_bounds", "f8", ("time", "nv"))
    cbnds.units = tvar.units
    cbnds.calendar = "standard"
    cbnds.coverage_content_type = "coordinate"
    cbnds[:, :] = time_bounds

    for name, width, edges in (
        ("depth", None, DEPTH_EDGES),
        ("lat", LAT_CELL, None),
        ("lon", LON_CELL, None),
    ):
        centres = np.asarray(src[name][...], dtype="f8")
        bnds = np.column_stack([edges[:-1], edges[1:]]) if edges is not None else cell_bounds(centres, width)
        bvar = out.createVariable(f"{name}_bnds", "f4", (name, "nv"))
        # CF 7.1: a boundary variable inherits units from its parent and must not carry its own.
        bvar.coverage_content_type = "coordinate"
        bvar[:, :] = bnds
        out[name].bounds = f"{name}_bnds"

    wl = out.createVariable("radiation_wavelength", "f4")
    wl.standard_name = "radiation_wavelength"
    wl.long_name = "wavelength of the backscattering measurement"
    wl.units = "nm"
    wl.coverage_content_type = "coordinate"
    wl.comment = "Nominal centre wavelength of the float backscattering sensors."
    wl[...] = np.float32(WAVELENGTH_NM)

    if role == "raw":
        nb = np.asarray(src["n_bbp"][...], dtype="f8")
        nfill = getattr(src["n_bbp"], "_FillValue", None)
        valid = np.isfinite(nb) & (nb > 0) & ((nb != nfill) if nfill is not None else True)
        flag = np.full(nb.shape, -1, dtype="i1")
        flag[valid & (nb > LOW_PRECISION_N)] = 0
        flag[valid & (nb <= LOW_PRECISION_N)] = 1
        fvar = out.createVariable(
            "low_precision_flag", "i1", ("time", "lon", "lat", "depth"), fill_value=np.int8(-1),
            **({"zlib": True, "complevel": 4, "shuffle": True} if compress else {}),
        )
        fvar.long_name = "flag for cells whose large-particle quantities have low precision"
        fvar.flag_values = np.array([0, 1], dtype="i1")
        fvar.flag_meanings = "n_bbp_above_100 n_bbp_100_or_fewer"
        fvar.coverage_content_type = "qualityInformation"
        fvar.coordinates = "month"
        fvar.comment = (
            f"Derived from n_bbp: 1 where the cell holds {LOW_PRECISION_N} or fewer backscattering "
            "measurements, the threshold below which matchups were excluded from the flux validation "
            "in the accompanying paper; large-particle quantities (bbl, bbx, number concentrations and "
            "the fluxes and sizes that depend on them) are poorly sampled there. Fill where the cell has "
            "no measurements."
        )
        fvar[...] = flag
        print(f"  low_precision_flag: {int((flag == 0).sum())} cells above {LOW_PRECISION_N}, {int((flag == 1).sum())} at or below")

    if role == "raw" and offset_field is not None:
        from scipy.io import loadmat

        m = loadmat(offset_field)
        # MATLAB (depth, lat, lon, month) -> file (time, lon, lat, depth)
        mo = np.transpose(m["mo"], (3, 2, 1, 0)).astype("f4")
        nfl = np.transpose(m["nfl"], (3, 2, 1, 0)).astype("i2")
        comp = {"zlib": True, "complevel": 4, "shuffle": True} if compress else {}
        ovar = out.createVariable("bbp_deep_offset", "f4", ("time", "lon", "lat", "depth"),
                                  fill_value=np.float32(-9999.0), **comp)
        ovar.long_name = "mean deep-alignment offset applied to the backscattering in the cell"
        ovar.units = "m-1"
        ovar.coverage_content_type = "auxiliaryInformation"
        ovar.coordinates = "month radiation_wavelength"
        ovar.cell_methods = CELL_METHODS_RAW
        ovar.comment = (
            "Mean of the additive per-float offsets applied to align deep backscattering between "
            "floats (GLOBESINK_BBP700_deep_offsets.xlsx), weighted by each float's number of "
            "measurements in the cell, exactly as the cell means are. The offset was added to every "
            "backscattering measurement of a float before size fractionation, so it is carried by "
            "the baseline (bbr + bbs) and, through bbs, by POCs and flux_POCs; the spike fractions are "
            "unaffected. Subtracting it from bbr + bbs approximates the unaligned baseline (only "
            "approximately for bbr, which is estimated per water column from smoothed fields). "
            "Floats with no neighbour within the search radius were not aligned and count as zero "
            "offset; in the published v1.0 run these were 11 floats, 0.16 % of the measurements, "
            "present in 324 cells and the only floats in 109. Computed by "
            "GLOBESINK_data_export/GLOBESINK_deep_offset_field.m, which reproduces n_bbp in every cell."
        )
        ovar[...] = np.where(np.isfinite(mo), mo, np.float32(-9999.0))
        fvar2 = out.createVariable("n_floats", "i2", ("time", "lon", "lat", "depth"),
                                   fill_value=np.int16(-1), **comp)
        fvar2.long_name = "number of distinct floats contributing backscattering measurements to the cell"
        fvar2.units = "1"
        fvar2.coverage_content_type = "auxiliaryInformation"
        fvar2.coordinates = "month"
        fvar2.comment = "Counted over all years for the calendar month; fill where the cell holds no measurements."
        fvar2[...] = np.where(nfl > 0, nfl, -1).astype("i2")
        print(f"  bbp_deep_offset and n_floats added ({int(np.isfinite(mo).sum())} cells)")

    if role == "raw" and bbx_flux_term:
        up_new, change = bbx_flux_upper(src)
        uvar = out[BBX_UPPER_VAR]
        uvar.set_auto_mask(False)
        current = np.asarray(uvar[...])
        uvar[...] = np.where(change, up_new.astype(current.dtype), current)
        uvar.long_name = BBX_UPPER_LONG_NAME
        uvar.comment = (
            variable_comment(BBX_UPPER_VAR)
            + " "
            + BBX_UPPER_NOTE.format(
                version=PRODUCT_VERSION, a=BBX_FIT_INTERCEPT, b=BBX_FIT_SLOPE, w=BBX_SINKING_FACTOR,
                n=int(change.sum()),
            )
        )
        fold_note = (
            f" : estimate of the >800 um flux folded in quadrature into {BBX_UPPER_VAR} "
            f"({int(change.sum())} cells; formula in its comment)"
        )
        print(f"  >800 um flux term folded into {BBX_UPPER_VAR} ({int(change.sum())} cells changed)")

    if status is not None:
        svar = out.createVariable(
            "cell_status", "i1", ("time", "lon", "lat", "depth"), fill_value=np.int8(-1)
        )
        svar.long_name = "provenance of the value in this grid cell"
        svar.flag_values = np.array([0, 1, 2], dtype="i1")
        svar.flag_meanings = "observed_smoothed interpolated observed_below_min_n_replaced"
        svar.coverage_content_type = "qualityInformation"
        svar.comment = (
            "Derived by comparing this file with the raw climatology: 0 where the raw cell held at "
            f"least min_n = {MIN_N} backscattering measurements, 2 where the raw cell held data but "
            "fewer than min_n, so that it was removed and refilled from its neighbours, 1 where the "
            "raw cell held no data at all. The flag describes the backscattering-derived fields, "
            "whose cells share one mask; the reference physical and biogeochemical climatologies "
            "have slightly different coverage."
        )
        svar[...] = status

    for key, value in global_attributes(
        role=role, src_history=str(getattr(src, "history", "")), upgraded=upgraded
    ).items():
        setattr(out, key, value)
    if role == "raw" and bbx_flux_term:
        out.history += f"\n{upgraded}{fold_note}"
    if masked_counts:
        total = sum(masked_counts.values())
        out.history += (
            f"\n{upgraded} : {total} non-finite values in "
            f"{len(masked_counts)} variables replaced with _FillValue"
        )
        print(f"  masked {total} non-finite values in {len(masked_counts)} variables")
    if bbx_counts:
        ncells = int(bbx_mask.sum())
        out.history += (
            f"\n{upgraded} : {ncells} grid cells whose >800 um fields were corrupted by garbage "
            f"BBP700 readings set to _FillValue in {', '.join(sorted(bbx_counts))} "
            f"({sum(bbx_counts.values())} values; cells listed in {CORRUPT_BBX_CSV})"
        )
        print(f"  masked {ncells} corrupt >800 um cells ({sum(bbx_counts.values())} values)")
    if temp_log:
        out.history += f"\n{upgraded} : TEMP above {TEMP_LIMIT:g} degC set to _FillValue (v1.0 value: " + "; ".join(temp_log) + ")"
        print(f"  masked {len(temp_log)} TEMP cell(s) above {TEMP_LIMIT:g} degC")

    out.close()
    src.close()
    print(f"  wrote {out_path.stat().st_size / 1e6:.1f} MB")


# Fields carrying the >800 um spike signal, which garbage BBP700 readings corrupt (see corrupt_bbx_cells).
CORRUPT_BBX_VARS = (
    "bbx", "bbx_precision_upper", "bbx_precision_lower",
    "C_800", "C_800_precision_upper", "C_800_precision_lower",
    "var_bbml", "var_bbml_precision_upper", "var_bbml_precision_lower",
)
CORRUPT_BBX_CSV = "GLOBESINK_v1.1_masked_bbx_cells.csv"
# Unadjusted TEMP above this is a garbage reading (one raw cell in v1.0: 2311.4 degC, June, 60 S 168 E,
# 5 m; TEMP_ADJUSTED there is normal). Every other TEMP value in both files is between -1.91 and 31.3.
TEMP_LIMIT = 40.0


def corrupt_temp_cells(path: Path) -> np.ndarray:
    """Cells of the unadjusted TEMP field above TEMP_LIMIT."""
    with nc.Dataset(path) as d:
        d.set_auto_mask(False)
        t = _floats(d["TEMP"]) if "TEMP" in d.variables else None
    if t is None:
        return np.zeros((), dtype=bool)
    with np.errstate(invalid="ignore"):
        return t > TEMP_LIMIT
V_SAMPLE_L = 0.01  # litres sampled per bbp measurement; C_800 * n_bbp * V_SAMPLE_L = particles counted
PER_PARTICLE_LIMIT = 1.0  # m-1: the implausible-value limit the MATLAB code now applies to raw BBP700
INTERP_BBX_LIMIT = 5e-3  # m-1: smoothed bbx; no cells lie between 5e-3 and 1e-2, 99.9th pct is 1.4e-4
INTERP_VAR_LIMIT = 1e-2  # (m-1)^2: smoothed var_bbml; no cells lie between 1e-3 and 1e-2


def _floats(var: nc.Variable) -> np.ndarray:
    a = np.asarray(var[...], dtype="f8")
    fill = getattr(var, "_FillValue", None)
    if fill is not None:
        a = np.where(a == fill, np.nan, a)
    return a


def corrupt_bbx_cells(raw_path: Path, interp_path: Path) -> dict[str, np.ndarray]:
    """Cells whose >800 um fields were corrupted by garbage BBP700 readings in v1.0.

    v1.0 applied neither the Argo QC flags nor a plausibility limit, so isolated garbage values
    (1e28-1e33 m-1 in floats 4901803, 6902667 and 6902743; repeated 33-37 m-1 near-surface values
    in floats 5904924, 5905022, 5905167, 5905199 and 1901347, nearly all DAC-flagged 3 or 4) were
    binned as >800 um spikes. Raw file: a cell is corrupt when its bbx per counted >800 um particle
    exceeds 1 m-1, i.e. it must contain a reading above the plausibility limit the MATLAB code now
    applies (GLOBESINK_mask_implausible_values.m). Across the 39,230 cells with a counted particle
    this separates cleanly: 99 % lie below 0.043 m-1, 2 cells between 1 and 10, 61 above 10.
    Smoothed file: the 3x3 running median passes an outlier through where data are sparse and the
    interpolation spreads it, so cells are flagged by value, at thresholds that fall in empty gaps
    of the distributions.
    """
    with nc.Dataset(raw_path) as r:
        r.set_auto_mask(False)
        bbx, n, c800 = (_floats(r[v]) for v in ("bbx", "n_bbp", "C_800"))
    counted = np.round(c800 * n * V_SAMPLE_L)
    with np.errstate(invalid="ignore", divide="ignore", over="ignore"):
        per_particle = np.where(counted > 0, bbx * n / counted, np.nan)
        raw_bad = per_particle > PER_PARTICLE_LIMIT
    with nc.Dataset(interp_path) as s:
        s.set_auto_mask(False)
        sbbx, svar = _floats(s["bbx"]), _floats(s["var_bbml"])
    with np.errstate(invalid="ignore"):
        interp_bad = (sbbx > INTERP_BBX_LIMIT) | (svar > INTERP_VAR_LIMIT)
    return {"raw": raw_bad, "interp": interp_bad}


def write_corrupt_bbx_csv(out_dir: Path, src_dir: Path, masks: dict[str, np.ndarray]) -> None:
    """List every masked cell with its v1.0 values, so the change is fully traceable."""
    rows = []
    for role, fname in (("raw", RAW_FILE), ("interp", INTERP_FILE)):
        with nc.Dataset(src_dir / fname) as d:
            d.set_auto_mask(False)
            vals = {v: _floats(d[v]) for v in ("bbx", "C_800", "var_bbml", "n_bbp") if v in d.variables}
            coords = {v: np.asarray(d[v][...]) for v in ("month", "lon", "lat", "depth")}
        for im, ilon, ilat, iz in zip(*np.nonzero(masks[role])):
            rows.append(
                [fname, int(coords["month"][im]), float(coords["lon"][ilon]), float(coords["lat"][ilat]),
                 float(coords["depth"][iz])]
                + [f"{vals[v][im, ilon, ilat, iz]:.6g}" for v in ("n_bbp", "bbx", "C_800", "var_bbml")]
            )
    with open(out_dir / CORRUPT_BBX_CSV, "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["file", "month", "lon", "lat", "depth", "n_bbp_v1.0", "bbx_v1.0", "C_800_v1.0",
                    "var_bbml_v1.0"])
        w.writerows(rows)
    print(f"\nlisted {len(rows)} masked cells in {CORRUPT_BBX_CSV}")


def write_variable_summary(raw_path: Path, interp_path: Path, out_path: Path) -> None:
    """The human-readable variable summary spreadsheet shipped with each release, read from the final files.

    One row a variable, in the raw file's order, then the variables only in the smoothed, interpolated
    file (e.g. `cell_status`); the last column says which file(s) hold it."""
    import pandas as pd

    rows: dict[str, dict] = {}
    for path, which in ((raw_path, "raw"), (interp_path, "smoothed, interpolated")):
        with nc.Dataset(path) as d:
            for name, var in d.variables.items():
                if name in rows:
                    rows[name]["File"] = "both"
                    continue
                scalar = var.ndim == 0
                units = getattr(var, "units", "")
                rows[name] = {
                    "GLOBESINK Netcdf Variable Name": name,
                    "Value (if variable is scalar)": float(var[...]) if scalar else None,
                    "Units (blank if unitless)": "" if units == "1" else units,
                    "CF Standard Name": getattr(var, "standard_name", ""),
                    "Argo Source Variable": getattr(var, "source_variable_name", ""),
                    # MATLAB order (depth x lat x lon x time), as in the v1.0 spreadsheet
                    "Variable Size": "1" if scalar else "x".join(str(n) for n in reversed(var.shape)),
                    "Variable Description": getattr(var, "long_name", ""),
                    "Comment": getattr(var, "comment", ""),
                    "File": f"{which} only",
                }
    pd.DataFrame(list(rows.values())).to_excel(out_path, index=False)
    print(f"wrote {out_path.name} ({len(rows)} variables)")


def verify(
    src_path: Path,
    out_path: Path,
    *,
    mask_nonfinite: bool,
    bbx_mask: np.ndarray | None = None,
    bbx_flux_term: bool = False,
    temp_mask: np.ndarray | None = None,
) -> bool:
    """Check every v1.0 value survives unchanged in v1.1. Returns True when they all do."""
    print(f"\nverifying {out_path.name} against {src_path.name}")
    src = nc.Dataset(src_path)
    out = nc.Dataset(out_path)
    for d in (src, out):
        d.set_auto_mask(False)
        d.set_auto_scale(False)
    ok = True
    for name, var in src.variables.items():
        if name not in out.variables:
            print(f"  MISSING in v1.1: {name}")
            ok = False
            continue
        a = np.asarray(var[...])
        b = np.asarray(out[name][...])
        if var.ndim == 0 and var.dtype == np.float64:
            a = a.astype("f4")  # D-11: scalars written as single precision
        if a.shape != b.shape:
            print(f"  SHAPE differs for {name}: {a.shape} vs {b.shape}")
            ok = False
            continue
        if mask_nonfinite and np.issubdtype(a.dtype, np.floating):
            fill = getattr(var, "_FillValue", None)
            bad = ~np.isfinite(a)
            if bad.any():
                if fill is None or not np.all(b[bad] == fill):
                    print(f"  non-finite cells of {name} were not replaced with _FillValue")
                    ok = False
                a = np.where(bad, b, a)  # compare the finite cells only
        if bbx_mask is not None and name in CORRUPT_BBX_VARS:
            fill = getattr(var, "_FillValue", None)
            if fill is None or not np.all(b[bbx_mask] == fill):
                print(f"  corrupt >800 um cells of {name} were not replaced with _FillValue")
                ok = False
            a = np.where(bbx_mask, b, a)  # compare the cells outside the mask only
        if temp_mask is not None and name == "TEMP" and temp_mask.any():
            fill = getattr(var, "_FillValue", None)
            if fill is None or not np.all(b[temp_mask] == fill):
                print("  corrupt TEMP cells were not replaced with _FillValue")
                ok = False
            a = np.where(temp_mask, b, a)
        if bbx_flux_term and name == BBX_UPPER_VAR and BBX_UPPER_VAR in out.variables and "bbl" in src.variables:
            up_new, change = bbx_flux_upper(src)
            a = np.where(change, up_new.astype(a.dtype), a)  # the expected v1.1 value, recomputed from v1.0
            print(f"  {name}: {int(change.sum())} cells expected to carry the >800 um term")
        same = np.array_equal(a, b, equal_nan=np.issubdtype(a.dtype, np.floating))
        if not same:
            diff = int((a != b).sum())
            print(f"  VALUES differ for {name}: {diff} elements")
            ok = False
    added = sorted(set(out.variables) - set(src.variables))
    print(f"  variables added: {', '.join(added) if added else 'none'}")
    print("  values identical" if ok else "  VALUES NOT IDENTICAL")
    src.close()
    out.close()
    return ok


def report(src_dir: Path) -> None:
    """Print what the metadata upgrade cannot fix: non-finite, extreme and empty fields."""
    for fname in (RAW_FILE, INTERP_FILE):
        path = src_dir / fname
        print(f"\n### {fname}")
        with nc.Dataset(path) as d:
            empty, nonfinite = [], []
            for name, var in d.variables.items():
                a = var[:]
                if np.ma.count(a) == 0:
                    empty.append(name)
                    continue
                vals = np.asarray(a[~np.ma.getmaskarray(a)]) if np.ma.isMaskedArray(a) else np.asarray(a)
                bad = int((~np.isfinite(vals)).sum())
                if bad:
                    nonfinite.append((name, bad, vals.size))
            if empty:
                print(f"  all values missing: {', '.join(empty)}")
            for name, bad, size in nonfinite:
                print(f"  non-finite {bad:>7d} of {size:>8d} ({100 * bad / size:6.3f} %)  {name}")
            bbx = d["bbx"][:]
            vals = np.asarray(bbx[~np.ma.getmaskarray(bbx)])
            vals = vals[np.isfinite(vals)]
            print(
                f"  bbx: median {np.median(vals):.3g}, 99.9th pct {np.percentile(vals, 99.9):.3g}, "
                f"max {vals.max():.3g}; {int((vals > 0.01).sum())} cells > 0.01 m-1"
            )
    print(
        "\nThese are v1.0 data issues, not metadata issues. A metadata-only v1.1 keeps them; "
        "--mask-nonfinite replaces non-finite values with _FillValue (which changes those cells)."
    )


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--src", type=Path, required=True, help="directory holding the published v1.0 files, or the MATLAB export in --mode export")
    p.add_argument("--mode", choices=("upgrade", "export"), default="upgrade")
    p.add_argument("--product-version", help="product_version (export mode)")
    p.add_argument("--coverage-end", help="last day of observations, YYYY-MM-DD (export mode)")
    p.add_argument("--dataset-doi", help="DOI of this version (TBD until reserved or minted on Zenodo)")
    p.add_argument("--code-version", help="git tag or commit of the processing code (export mode)")
    p.add_argument("--code-doi", help="Zenodo DOI of the processing code (export mode)")
    p.add_argument("--paper-doi", help="DOI of the data paper")
    p.add_argument("--out", type=Path, help="directory to write the v1.1 files into")
    p.add_argument("--report", action="store_true", help="print data-quality diagnostics and stop")
    p.add_argument("--verify-only", action="store_true", help="verify files already written in --out")
    p.add_argument("--compress", action="store_true", help="zlib-compress the gridded variables")
    p.add_argument(
        "--mask-nonfinite",
        action="store_true",
        help="replace Inf/NaN values with _FillValue (changes those cells; not a metadata-only change)",
    )
    p.add_argument(
        "--mask-corrupt-bbx",
        action="store_true",
        help="replace the >800 um fields (bbx, C_800, var_bbml and their bounds) with _FillValue in "
        f"cells corrupted by garbage BBP700 readings, listing each cell in {CORRUPT_BBX_CSV}",
    )
    p.add_argument(
        "--deep-offset-field",
        type=Path,
        help="output of GLOBESINK_deep_offset_field.m; adds bbp_deep_offset and n_floats to the raw file",
    )
    p.add_argument(
        "--bbx-flux-term",
        action="store_true",
        help=f"fold an estimate of the >800 um flux into {BBX_UPPER_VAR} (raw file; changes those cells)",
    )
    p.add_argument(
        "--mask-corrupt-temp",
        action="store_true",
        help=f"replace unadjusted TEMP above {TEMP_LIMIT:g} degC with _FillValue (one raw cell in v1.0)",
    )
    p.add_argument("--allow-placeholders", action="store_true", help="write even with TBD metadata")
    args = p.parse_args(argv)

    global MODE, PRODUCT_VERSION, COVERAGE_END, DATASET_DOI, CODE_VERSION, CODE_DOI, PAPER_DOI
    MODE = args.mode
    if MODE == "export":
        if args.mask_corrupt_bbx:
            p.error("--mask-corrupt-bbx applies only to the v1.0 upgrade")
        if args.mask_corrupt_temp:
            p.error("--mask-corrupt-temp applies only to the v1.0 upgrade")
        PRODUCT_VERSION = args.product_version or p.error("--product-version is required in export mode")
        COVERAGE_END = dt.date.fromisoformat(args.coverage_end or p.error("--coverage-end is required in export mode"))
    DATASET_DOI = args.dataset_doi or DATASET_DOI
    CODE_VERSION = args.code_version or CODE_VERSION
    CODE_DOI = args.code_doi or CODE_DOI
    PAPER_DOI = args.paper_doi or PAPER_DOI

    if args.report:
        report(args.src)
        return 0
    if args.out is None:
        p.error("--out is required unless --report is given")

    missing = placeholders_present()
    if missing:
        print(f"placeholder metadata still present: {', '.join(missing)}")
        if not (args.allow_placeholders or args.verify_only):
            print("refusing to write; pass --allow-placeholders for a draft run")
            return 2

    args.out.mkdir(parents=True, exist_ok=True)
    pairs = [(RAW_FILE, "raw"), (INTERP_FILE, "interp")]
    masks = corrupt_bbx_cells(args.src / RAW_FILE, args.src / INTERP_FILE) if args.mask_corrupt_bbx else None
    temp_masks = (
        {role: corrupt_temp_cells(args.src / fname) for fname, role in pairs} if args.mask_corrupt_temp else None
    )
    if not args.verify_only:
        for fname, role in pairs:
            upgrade(
                args.src / fname,
                args.out / fname,
                role=role,
                raw_path=args.src / RAW_FILE,
                compress=args.compress,
                mask_nonfinite=args.mask_nonfinite,
                bbx_mask=masks[role] if masks else None,
                offset_field=args.deep_offset_field,
                bbx_flux_term=args.bbx_flux_term,
                temp_mask=temp_masks[role] if temp_masks else None,
            )
        if masks:
            write_corrupt_bbx_csv(args.out, args.src, masks)
        write_variable_summary(args.out / RAW_FILE, args.out / INTERP_FILE, args.out / VARIABLE_SUMMARY_XLSX)
    ok = all(
        [
            verify(
                args.src / fname,
                args.out / fname,
                mask_nonfinite=args.mask_nonfinite,
                bbx_mask=masks[role] if masks else None,
                bbx_flux_term=args.bbx_flux_term,
                temp_mask=temp_masks[role] if temp_masks else None,
            )
            for fname, role in pairs
        ]
    )
    changed = [f for f, on in (("non-finite", args.mask_nonfinite), ("corrupt >800 um", args.mask_corrupt_bbx), ("corrupt TEMP", args.mask_corrupt_temp)) if on]
    note = f" apart from the masked {' and '.join(changed)} cells" if changed else ""
    if args.bbx_flux_term:
        note += f"{' and' if note else ' apart from'} the >800 um term in {BBX_UPPER_VAR}"
    ref = "the MATLAB export" if MODE == "export" else "v1.0"
    print(f"\nall values identical to {ref}{note}" if ok else "\nVERIFICATION FAILED")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
