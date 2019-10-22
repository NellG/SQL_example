-- script to pull process data for a certain part on a subset of fielded products
select distinct
  field.psn as "Product_SN",
  field.ptsn as "Part_SN", 
  ops.group as "Group",
  ops.position as "Position", 
  -- insert batch number from table most likely to have correct formatting
  (case
    when qc.batch is not null then qc.batch
    when proc.batch is not null the proc.batch
    else ops.batch
    end) as "Batch",
  -- extract only final digits from oven number (range 2:18), entries have format OVEN-##, OVEN-#, ##, or #
  (case
    when isnumeric(ops.oven) then ops.oven
    when substring(ops.oven from char_length(ops.oven)-1 for 1) = 1 then substring(ops.oven from char_length(ops.oven)-1)
    else substring(ops.oven from char_length(ops.oven))
    end) as "Oven_corr",
  -- get machine number (range 1-4), entries have format Mach-# or #
  (case
    when isnumeric(mach.mach) then mach.mach
    else substring(mach.mach from char_length(mach.mach))
    end) as "Mach_cor",
  mach.set1 as "Setting_1", 
  mach.set2 as "Setting_2", 
  mach.fd1 as "Feedstock_1", 
  mach.fd2 as "Feedstock_2",
  -- process variable A is sometimes recorded in column pv_A and sometimes recorded in column pvar_A, never in both
  -- the process variable is numeric, skipped columns will contain text "NA", combine these two columns into one
  (case
    when isnumeric(mach.pv_A) then mach.pv_A
    when isnumeric(mach.pvar_A) then mach.pvar_A
    else NULL
    end) as "Proc_Var_A",
  qc.ms1 as "Measurement_1",
  qc.ms2 as "Measurement_2"
from schema.field_hardware_table field
inner join schema.operations_data_table ops on field.psn = ops.psn
left join schema.machining_data_table mach on ops.group = mach.group
left join schema.quality_data_table qc on ops.group = qc.group
-- desired subset of fielded products
where field.psn in ('P001', 'P008', 'P012', 'P125', 'P304', 'P419')
-- due to typos in qc data, remove entries where the qc batch number does not match the machine batch number
and (mach.batch = qc.batch or mach.batch is null or qc.batch is null)
order by ops.group, field.psn asc
