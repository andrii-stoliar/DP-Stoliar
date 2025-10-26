import os
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec

from figFcns_TeX import *

# ===== Params =====
figSaveDir = '../fig'
os.makedirs(figSaveDir, exist_ok=True)

figName = 'ts_prevodova_sensors3'

# load CSV
data_main = pd.read_csv('../dataRepo/ts_prevodova3.csv', header=None).values
t  = data_main[:, 0]
y1 = data_main[:, 3]   # Snímač 1
y2 = data_main[:, 4]   # Snímač 2

# ===== Panel =====
figPlotParam = fcnDefaultFigSize(7, 0.17, 0.88, 0.12, 0.40, 13)
fig = plt.figure(0, figsize=figPlotParam[0:2])
subPlots = gridspec.GridSpec(2, 1, height_ratios=[1, 1])


fcn_setFigStyle_basicTimeSeries(fig, figPlotParam, ['Čas [s]', '', ''])

# --- Horný graf: Snímač 1 ---
ax0 = plt.subplot(subPlots[0])
ax0.plot(t, y1, '-', lw=0.5, ms = 2, color='k', drawstyle='default')
fcnDefaultAxisStyle(ax0)
ax0.grid(True, which='both', linestyle='--', linewidth=0.1, color='k')
ax0.set_xlabel('Čas [s]', ha='left', va='top')
ax0.xaxis.set_label_coords(1.05, -0.07, transform=ax0.transAxes)
ax0.set_ylabel('Snímač 1 [V]', ha='right', va='bottom', rotation=0)
ax0.yaxis.set_label_coords(-0.07, 1.05, transform=ax0.transAxes)
ax0.set_ylim(3, 10)

# --- Dolný graf: Snímač 2 ---
ax1 = plt.subplot(subPlots[1])
ax1.plot(t, y2, '-', lw=0.5, ms = 2, color='k', drawstyle='default')
fcnDefaultAxisStyle(ax1)
ax1.grid(True, which='both', linestyle='--', linewidth=0.1, color='k')
ax1.set_xlabel('Čas [s]', ha='left', va='top')
ax1.xaxis.set_label_coords(1.05, -0.07, transform=ax1.transAxes)
ax1.set_ylabel('Snímač 2 [V]', ha='right', va='bottom', rotation=0)
ax1.yaxis.set_label_coords(-0.07, 1.05, transform=ax1.transAxes)
ax1.set_ylim(3, 10)

# ===== Layout =====
fcnDefaultLayoutAdj(fig, figPlotParam[2], figPlotParam[3],
                    figPlotParam[4], figPlotParam[5])

# ===== Save =====
plt.savefig(os.path.join(figSaveDir, f"{figName}.png"))
plt.close()
