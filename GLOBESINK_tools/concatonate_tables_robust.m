% table_out = concatonate_tables_robust(table1,table2);
%
% concatonates two tables that don't all have the same variables, filling
% the blanks with nans

function table_out = concatonate_tables_robust(table1,table2)
    vars1 = table1.Properties.VariableNames;
    vars2 = table2.Properties.VariableNames;
    newvars1 = setdiff(vars2,vars1);
    newvars2 = setdiff(vars1,vars2);
    for ii = 1:length(newvars1)
        table1.(newvars1{ii})(:,1) = nan;
    end
    for ii = 1:length(newvars2)
        table2.(newvars2{ii})(:,1) = nan;
    end
    vars1 = table1.Properties.VariableNames;
    table_out = [table1; table2(:,vars1)];
end