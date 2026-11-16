# GLOBESINK processing code, v1.1

MATLAB code that produced the **GLOBESINK** global BGC-Argo climatology of
size-fractionated optical backscattering (b<sub>bp</sub>), particulate organic carbon (POC),
POC sinking flux and particle size, and the Python script that produced dataset v1.1 from the
published v1.0 files. It accompanies:

- the data paper: Briggs, N., Henson, S. A., Flohr, A. and Hilder, H., *GLOBESINK: A global
  climatology of sinking organic carbon flux and particle size from optical backscattering
  measurements*, Earth System Science Data (doi:10.5194/essd-2026-566);
- the dataset: GLOBESINK monthly POC flux and particle size climatology, concept
  doi:10.5281/zenodo.19558503 (v1.0: doi:10.5281/zenodo.19558504).

The repository holds only what is needed to build the dataset and to understand how it was
built. It is research code provided for transparency, inspection and adaptation, not a turnkey
package: it runs against the Argo GDAC files and the GEBCO One Minute Grid, which you obtain
yourself, a full global run takes many hours, and several stages are scripts run by hand in the
order given below.

Licence: [MIT](LICENSE). How to cite: [CITATION.cff](CITATION.cff). Please cite the data paper
and the dataset as well as the code.

---

## 1. Processing pipeline

Each stage reads and writes `.mat` or NetCDF files under the folders set in the configuration
file (§3). Run the stages in this order.

### Stage 1: download, QC and per-cast binning

Master script: [`GLOBESINK_BGC_Argo_data_processing_v3.m`](GLOBESINK_BGC_Argo_data_processing_v3.m),
driven by the options file
[`GLOBESINK_options/set_GLOBESINK_options_GLOBESINK_global_2025.m`](GLOBESINK_options/set_GLOBESINK_options_GLOBESINK_global_2025.m).
Each step is switched on or off by a flag in the options struct `GLOBESINK_opts`.

1. **Find profiles**: `get_BGC_profile_locations`, `get_bio_index_profile_locations` and the
   per-float lookups `get_BGC_profile_locations_by_WMO`, `get_bio_file_profile_locations_by_WMO`.
2. **Metadata**: `get_Argo_metadata_table`, `download_BGC_Argo_metadata`, `get_Argo_float_type`,
   `get_Argo_sensor_model_names`.
3. **Download**: `download_BGC_Argo_data`, `download_BGC_Argo_bio_files`.
4. **Load**: `load_BGC_Argo_data`, then `GLOBESINK_merge_RT_DM_data` (real-time and
   delayed-mode data merged), saved as one `.mat` file per float.
5. **Quality control**:
   - CDOM spikes: `run_GLOBESINK_auto_QC_cdom_spikes` → `GLOBESINK_cdom_data_QC`;
   - automated b<sub>bp</sub> QC: `run_GLOBESINK_auto_QC_bbp` → `GLOBESINK_bbp_data_QC`
     (range test, local outliers and the exclusion around them);
   - visual QC: `run_GLOBESINK_manual_QC_bbp` → `GLOBESINK_bbp_add_manual_QC`, which applies
     the visual-QC checklist in `GLOBESINK_ancillary_data/`.
6. **Per-cast depth binning**: `run_GLOBESINK_percast_binning` → `GLOBESINK_per_profile_binning`
   (with `GLOBESINK_calculate_mean_ESD` and `GLOBESINK_get_spike_uncertainties`), and the
   nearby bathymetry of each cast.
7. **Per-float plots** (optional): `plot_individual_BGC_float_sections`,
   `plot_individual_BGC_float_profiles`, `plot_all_BGC_float_sections_combined`,
   `GLOBESINK_plot_pc_bin_climatological_timeseries`.

### Stage 2: gridded product

1. [`GLOBESINK_binned_data/GLOBESINK_monthly_binning4.m`](GLOBESINK_binned_data/GLOBESINK_monthly_binning4.m)
   with `add_deep_bbp_offsets = 0`: monthly per-float bins (`GLOBESINK_monthly_perfloat_bins`,
   including the removal of data near shallow bathymetry) and the monthly climatology maps
   (`GLOBESINK_monthly_climatology_maps`, `GLOBESINK_yearly_monthly_maps`).
2. [`GLOBESINK_binned_data/get_GLOBESINK_deep_offsets.m`](GLOBESINK_binned_data/get_GLOBESINK_deep_offsets.m):
   aligns deep b<sub>bp</sub> between floats within 2000 km (`GLOBESINK_deep_bbp_offsets`).
3. `GLOBESINK_monthly_binning4.m` again with `add_deep_bbp_offsets = 1`
   (`apply_GLOBESINK_deep_offsets`).
4. [`GLOBESINK_binned_data/GLOBESINK_POC_flux_calculation_v2.m`](GLOBESINK_binned_data/GLOBESINK_POC_flux_calculation_v2.m):
   b<sub>bp</sub> to POC and POC flux, spatial smoothing and interpolation
   (`GLOBESINK_spatial_interpolation`), and uncertainty propagation
   (`GLOBESINK_combine_precisions`, `GLOBESINK_combine_systematic_errors`,
   `GLOBESINK_generate_relative_uncertainty`, `GLOBESINK_propagate_errors_linear`,
   `GLOBESINK_propagate_relative_errors`).
5. [`GLOBESINK_data_export/GLOBESINK_netcdf_file_creation.m`](GLOBESINK_data_export/GLOBESINK_netcdf_file_creation.m):
   writes the NetCDF files in the v1.0 format, using the variable table
   `GLOBESINK_ancillary_data/GLOBESINK_netcdf_variable_details.xlsx`.

The sections at the end of `GLOBESINK_monthly_binning4.m` that follow its last `save` only draw
diagnostic figures. They are left as they were run, but they are not needed for the dataset, and
its map figures read a plot-layout table that is not included.

### Stage 3: dataset v1.1

1. [`GLOBESINK_data_export/GLOBESINK_deep_offset_field.m`](GLOBESINK_data_export/GLOBESINK_deep_offset_field.m)
   builds the gridded field of applied deep offsets and the number of contributing floats from
   the aligned monthly bins and the per-float offset table. It stops unless it reproduces the
   published `n_bbp` in every cell.
2. [`GLOBESINK_data_export/cf_acdd_metadata/GLOBESINK_cf_acdd_metadata.py`](GLOBESINK_data_export/cf_acdd_metadata/GLOBESINK_cf_acdd_metadata.py)
   upgrades the v1.0 files to v1.1: CF-1.8 and ACDD-1.3 metadata, the two documented corrections
   of erroneous values, and the added fields. It compares every value with v1.0 and stops on any
   difference other than the documented corrections. The v1.1 files were made with:

   ```bash
   python GLOBESINK_cf_acdd_metadata.py --src <v1.0 folder> --out <v1.1 folder> \
       --compress --mask-nonfinite --mask-corrupt-bbx --mask-corrupt-temp --bbx-flux-term \
       --deep-offset-field <GLOBESINK_deep_offset_field.mat> \
       --dataset-doi <v1.1 DOI> --code-version v1.1 --code-doi <code DOI> --paper-doi 10.5194/essd-2026-566
   ```

`GLOBESINK_data_export/GLOBESINK_check_release_setup.m` checks the configuration, the bathymetry
loader and the metadata step on a new machine; `GLOBESINK_apply_cf_acdd_metadata.m` runs the
Python script from MATLAB.

---

## 2. Folders

| Folder | Contents |
|---|---|
| *(root)* | Master script and `get_BGC_Argo_data_and_plot_folders.m`. |
| `GLOBESINK_options/` | The options file used for the dataset. |
| `GLOBESINK_config/` | Configuration template and the functions that read it (§3). |
| `GLOBESINK_Argo_data_downloads/` | GDAC download functions. |
| `GLOBESINK_Argo_data_loading_functions/` | Index lookups, data loading, real-time/delayed-mode merge. |
| `GLOBESINK_QC_functions/` | Automated and visual b<sub>bp</sub> QC, CDOM spike QC. |
| `GLOBESINK_intermediate_processing_scripts/` | `run_*` scripts called by the master script. |
| `GLOBESINK_processing_functions/` | Mean particle size, number concentrations, spike uncertainties, deep offsets, uncertainty propagation. |
| `GLOBESINK_binned_data/` | Stage 2 scripts and their binning functions. |
| `GLOBESINK_data_export/` | NetCDF export, the v1.1 metadata script and the deep-offset field. |
| `GLOBESINK_plotting_functions/`, `GLOBESINK_plotting_scripts/` | The optional per-float plots of Stage 1. |
| `GLOBESINK_tools/` | General utilities: binning by edges, spike separation, filters, regressions, Martin-curve fits, the bathymetry loader. |
| `GLOBESINK_tools/bundled_nathantools/` | General helper functions from the author's own toolbox, as used for the dataset (§3). |
| `GLOBESINK_ancillary_data/` | Inputs read by the code: the visual-QC checklist (`binned_data_visual_QC_checklist_AF_NB_2025.xlsx`), the Argo and GLOBESINK grey lists read by the QC functions (`ar_greylist.txt`, `GLOBESINK_bbp_greylist.xlsx`), and the NetCDF variable table. |

---

## 3. Requirements and setup

| What | Where | What you do |
|---|---|---|
| Local paths | `GLOBESINK_config/GLOBESINK_config.m` | Copy [`GLOBESINK_config_template.m`](GLOBESINK_config/GLOBESINK_config_template.m) to `GLOBESINK_config.m` in the same folder and set `home_folder`, `argo_raw_folder` (any existing folder; this release does not use it), `gebco_file` and `python`. The copy is git-ignored. |
| Argo data | under `home_folder` | Stage 1 downloads the GDAC files (doi:10.17882/42182) into `BiogeochemicalArgo/data/` under `home_folder`. Outputs go under `BiogeochemicalArgo/data/` and `BiogeochemicalArgo/plots/`. |
| Bathymetry | `gebco_file` | The **GEBCO One Minute Grid, version 2.0 (November 2008)**, 1-D GMT netCDF format (`GRIDONE_1D.nc`), from GEBCO's historical grids. It is not redistributed here. [`load_global_bathymetry`](GLOBESINK_tools/load_global_bathymetry.m) reads it. A newer grid would need a change to the loader and would not reproduce the dataset exactly. |
| MATLAB | | Developed on R2022b–R2023b, with the Statistics and Machine Learning, Curve Fitting and Mapping toolboxes. Put the repository on the path with `addpath(genpath('<repo>'))`. |
| Python | `python` | Python 3 with numpy, pandas, netCDF4 and openpyxl, for Stage 3. |

**Third-party MATLAB functions, not redistributed here** (obtain them and put them on the path):

| Toolbox | Functions | Used for |
|---|---|---|
| TEOS-10 Gibbs SeaWater (GSW) Oceanographic Toolbox | `gsw_z_from_p` | depth of each sample in per-cast binning |
| AIR_SEA toolbox | `soradna1` | solar zenith angle for the night-only variables |
| Quantile regression | `mmqr`, `xbeta` | only the optional plot `GLOBESINK_plot_pc_bin_climatological_timeseries` |

**Bundled helper functions.** `GLOBESINK_tools/bundled_nathantools/` holds 12 general helper
functions (filters, distances, solar zenith angle, Poisson and particle-size-distribution
statistics, plot formatting) from the author's own toolbox, identical to the versions used for
the dataset. `get_sun_zenith_angle.m` keeps the yearday convention used for the dataset, which is
one day late; see the comment in the file.

---

## 4. Relation to the published files

- **Dataset v1.0** (13 May 2026) was made by this processing code, but it cannot be reproduced bit
  for bit from a single earlier commit of the development repository: the export code was
  committed about a month after the files were written, and the flux and uncertainty scripts two
  months after. This release gathers those files with the configuration of the published run,
  including the deep-offset search radius of 2000 km, and the helper functions above. It is the
  closest faithful record of the code that produced the dataset.
- **Dataset v1.1** is the v1.0 values with CF-1.8 and ACDD-1.3 metadata, two documented
  corrections of erroneous values that do not affect POC, POC flux or particle size, and added
  fields derived from the published run (Stage 3). The v1.1 files record this release's version
  and DOI in their `history` and `source_code` attributes. Their README and changelog describe
  the changes.
