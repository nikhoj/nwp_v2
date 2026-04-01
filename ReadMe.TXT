WRF + WPS Step-by-Step Guide (Simple Version)

Project root:
/lustre/work/{}/nwp

This guide runs a 24-hour forecast from 2026-03-31 00:00:00 to 2026-04-01 00:00:00.
This case uses one domain at 3 km grid spacing.

1. Go to the project folder
cd /lustre/work/{}/nwp

2. Prepare base folders
Make sure these folders exist:
- /lustre/work/{}/nwp/data
- /lustre/work/{}/nwp/geog
- /lustre/work/{}/nwp/WPS-4.5
- /lustre/work/{}/nwp/WRFV4.5.2

3. Download GFS data files (every 3 hours)
Go to data folder:
cd /lustre/work/{}/nwp/data

Download files:
BASE="https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.20260331/00/atmos"
for fhr in 000 003 006 009 012 015 018 021 024; do
    wget -c "${BASE}/gfs.t00z.pgrb2.0p25.f${fhr}"
done

Important:
Download f000 to f024. Do not skip forecast hours.
WRF needs boundary updates through the whole run.

4. Download static geog data (one-time)
cd /lustre/work/{}/nwp/geog
wget https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_high_res_mandatory.tar.gz
tar -xzf geog_high_res_mandatory.tar.gz

After extraction, the path should be:
/lustre/work/{}/nwp/geog/WPS_GEOG/

5. Build WRF and WPS (one-time)
Use your compiler and MPI environment first.
Then compile WRF and WPS.

If your build is already done, check these executables:
- /lustre/work/{}/nwp/WPS-4.5/geogrid.exe
- /lustre/work/{}/nwp/WPS-4.5/ungrib.exe
- /lustre/work/{}/nwp/WPS-4.5/metgrid.exe
- /lustre/work/{}/nwp/WRFV4.5.2/main/real.exe
- /lustre/work/{}/nwp/WRFV4.5.2/main/wrf.exe

6. Configure WPS namelist
Edit:
/lustre/work/{}/nwp/WPS-4.5/namelist.wps

Use these key values:
- max_dom = 1
- start_date = '2026-03-31_00:00:00'
- end_date   = '2026-04-01_00:00:00'
- interval_seconds = 10800
- e_we = 301
- e_sn = 301
- dx = 3000
- dy = 3000
- map_proj = 'lambert'
- ref_lat = 33.50
- ref_lon = -101.90
- truelat1 = 30.0
- truelat2 = 60.0
- stand_lon = -101.90
- geog_data_path = '/lustre/work/{}/nwp/geog/WPS_GEOG/'
- prefix = 'FILE'

7. Run geogrid
cd /lustre/work/{}/nwp/WPS-4.5
./geogrid.exe 2>&1 | tee geogrid.log

Check output file:
geo_em.d01.nc

8. Link GRIB files for ungrib
cd /lustre/work/{}/nwp/WPS-4.5
./link_grib.csh /lustre/work/{}/nwp/data/gfs.t00z.pgrb2.0p25.f0*

Select Vtable for GFS:
ln -sf ungrib/Variable_Tables/Vtable.GFS Vtable

9. Run ungrib
cd /lustre/work/{}/nwp/WPS-4.5
./ungrib.exe 2>&1 | tee ungrib.log

Check outputs:
FILE:2026-03-31_00
FILE:2026-03-31_03
...
FILE:2026-04-01_00

10. Run metgrid
cd /lustre/work/{}/nwp/WPS-4.5
./metgrid.exe 2>&1 | tee metgrid.log

Check outputs:
met_em.d01.2026-03-31_00:00:00.nc
...
met_em.d01.2026-04-01_00:00:00.nc

11. Prepare WRF run directory
cd /lustre/work/{}/nwp/WRFV4.5.2/test/em_real

Link met files:
ln -sf /lustre/work/{}/nwp/WPS-4.5/met_em.d01.* .

12. Create namelist.input
Create file:
/lustre/work/{}/nwp/WRFV4.5.2/test/em_real/namelist.input

Use the same dates and interval as WPS.
Use these critical values:
- max_dom = 1
- start = 2026-03-31_00:00:00
- end   = 2026-04-01_00:00:00
- interval_seconds = 10800
- e_we = 301
- e_sn = 301
- dx = 3000
- dy = 3000
- num_metgrid_levels = 34
- num_metgrid_soil_levels = 4
- time_step = 18

13. Run real.exe
cd /lustre/work/{}/nwp/WRFV4.5.2/test/em_real
./real.exe 2>&1 | tee real.log

Check success in rsl.error.0000:
real_em: SUCCESS COMPLETE REAL_EM INIT

Check files exist:
wrfinput_d01
wrfbdy_d01

14. Run wrf.exe
cd /lustre/work/{}/nwp/WRFV4.5.2/test/em_real
./wrf.exe 2>&1 | tee wrf.log

Monitor progress:
tail -f rsl.error.0000

15. If wrf.exe fails with CAMtr_volume_mixing_ratio missing
Error example:
CLWRF: 'CAMtr_volume_mixing_ratio' does not exist

Reason:
Files in /lustre/work/{}/nwp/WRFV4.5.2/run are missing.

Fix:
cd /lustre/work/{}/nwp
tar -xzf v4.5.2.tar.gz WRFV4.5.2/run

Then run wrf.exe again.

16. Useful quick checks
Check met_em files:
ls -1 /lustre/work/{}/nwp/WPS-4.5/met_em.d01.*

Check WRF input files:
ls -lh /lustre/work/{}/nwp/WRFV4.5.2/test/em_real/wrfinput_d01 /lustre/work/{}/nwp/WRFV4.5.2/test/em_real/wrfbdy_d01

Check final lines of log:
tail -n 50 /lustre/work/{}/nwp/WRFV4.5.2/test/em_real/rsl.error.0000

17. Notes
The floating-point warning in metgrid is common.
If met_em files are created and look correct, you can continue.

Keep namelist.wps and namelist.input times consistent.
If times do not match, real.exe will fail.

End of guide.
