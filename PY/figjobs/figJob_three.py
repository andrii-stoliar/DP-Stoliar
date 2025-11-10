import os
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec

from figFcns_TeX import *

# ===== Params =====
figSaveDir = '../fig'
os.makedirs(figSaveDir, exist_ok=True)

figName = 'ts_pb_vent6_spir4_ident_approximated_comparison'

# ===== Load CSV =====
data_main = pd.read_csv(
    '../dataRepo/pb_vent6_spir4_id_apprx.csv',
    header=None,
    skiprows=1  # skip first line
).values

# ===== Panel =====
figPlotParam = fcnDefaultFigSize(6, 0.17, 0.88, 0.12, 0.4, 13)
fig = plt.figure(0, figsize=figPlotParam[0:2])
subPlots = gridspec.GridSpec(1, 1)
ax0 = plt.subplot(subPlots[0])

# ===== Plot =====
ax0.plot(data_main[:, 0], data_main[:, 2], '-', lw=0.6, color='k', label='Spirála 1 – meraná')
ax0.plot(data_main[:, 0], data_main[:, 3], '--', lw=0.8, color='tab:blue',
         label='Spirála 1 – metóda najmenších štvorcov')
ax0.plot(data_main[:, 0], data_main[:, 4], '--', lw=0.8, color='tab:red',
         label='Spirála 1 – metóda fminsearch')

# ===== Style =====
fcnDefaultLayoutAdj(fig, figPlotParam[2], figPlotParam[3],
                    figPlotParam[4], figPlotParam[5])
fcn_setFigStyle_basicTimeSeries(
    fig, figPlotParam, ['Čas [s]', 'Spirála 1 [V]', ''])
ax0.grid(True, which='both', linestyle='--', linewidth=0.1, color='k')
ax0.legend(frameon=False, fontsize=8, loc='best')

plt.savefig(os.path.join(figSaveDir, f"{figName}.png"), dpi=600)
plt.close()
