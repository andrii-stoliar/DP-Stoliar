import os
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec

from figFcns_TeX import *

# ===== Params =====
figSaveDir = '../fig'
os.makedirs(figSaveDir, exist_ok=True)

figName = 'ts_pb_vent6_spir4_pidtune_sim'

# load CSV
data_main = pd.read_csv('../dataRepo/ts_pb_vent6_spir4_pidtune_sim.csv', header=None, skiprows=1).values
t  = data_main[:, 0]
ref = data_main[:, 1]
u = data_main[:, 2]      
y = data_main[:, 3]     

# ===== Panel =====
figPlotParam = fcnDefaultFigSize(9, 0.17, 0.88, 0.12, 0.40, 13)
fig = plt.figure(0, figsize=figPlotParam[0:2])
subPlots = gridspec.GridSpec(2, 1, height_ratios=[1, 1])

fcn_setFigStyle_basicTimeSeries(fig, figPlotParam, ['Čas [s]', '', ''])

# --- Upper plot
ax0 = plt.subplot(subPlots[0])

# black solid line
ax0.plot(t, y, '-', lw=0.6, color='k', label='Výstup')

# red dashed line
ax0.plot(t, ref, '--', lw=0.9, color='red', label='Referenčná krivka')

fcnDefaultAxisStyle(ax0)
ax0.grid(True, which='both', linestyle='--', linewidth=0.1, color='k')

ax0.set_xlabel('Čas [s]', ha='left', va='top')
ax0.xaxis.set_label_coords(1.05, -0.07, transform=ax0.transAxes)

ax0.set_ylabel('Výstup [V]', ha='right', va='bottom', rotation=0)
ax0.yaxis.set_label_coords(-0.07, 1.05, transform=ax0.transAxes)

ax0.set_ylim(0, 0.5)
ax0.legend(loc='upper right', fontsize=9)

# --- Lower plot
ax1 = plt.subplot(subPlots[1])

ax1.plot(t, u, '-', lw=0.6, color='k', label='Vstup – akčný zásah')

fcnDefaultAxisStyle(ax1)
ax1.grid(True, which='both', linestyle='--', linewidth=0.1, color='k')

ax1.set_xlabel('Čas [s]', ha='left', va='top')
ax1.xaxis.set_label_coords(1.05, -0.07, transform=ax1.transAxes)

ax1.set_ylabel('Vstup [V]', ha='right', va='bottom', rotation=0)
ax1.yaxis.set_label_coords(-0.07, 1.05, transform=ax1.transAxes)

ax1.set_ylim(-4, 6.5)

# ===== Layout =====
fcnDefaultLayoutAdj(fig, figPlotParam[2], figPlotParam[3],
                    figPlotParam[4], figPlotParam[5])

# ===== Save =====
plt.savefig(os.path.join(figSaveDir, f"{figName}.png"), dpi=300)
plt.close()
