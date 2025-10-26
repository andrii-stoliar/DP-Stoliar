import os
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
from figFcns_TeX import *

# ===== Nastavenia =====
figSaveDir = '../fig'
os.makedirs(figSaveDir, exist_ok=True)

figName = 'ts_idented_steps'

# ---- rozmery ~90 % A4 ----
figPlotParam = fcnDefaultFigSize(
    figSizeTotalHeight=18,   
    fig_lrPadding=0.17,      
    fig_top=0.90,
    fig_bottom=0.12,
    fig_hspace=0.40,       
    figSizePlotWidth=13      
)

# ===== Načítanie dát =====
data = pd.read_csv('../dataRepo/ts_identified_results.csv')

t = data['time']
y13_data = data['y13_data']; y23_data = data['y23_data']
y16_data = data['y16_data']; y26_data = data['y26_data']
y19_data = data['y19_data']; y29_data = data['y29_data']

y3n_model = data['y3n_model']; y3f_model = data['y3f_model']
y6n_model = data['y6n_model']; y6f_model = data['y6f_model']
y9n_model = data['y9n_model']; y9f_model = data['y9f_model']

# ===== Príprava grafu =====
fig = plt.figure(0, figsize=figPlotParam[0:2])
subPlots = gridspec.GridSpec(3, 2, height_ratios=[1, 1, 1])

# ---- Pomocná funkcia pre subplot ----
def plot_subplot(ax, t, y_data, y_model, title):
    ax.plot(t, y_data, 'k', lw=0.8, label='údaje')
    ax.plot(t, y_model, 'r--', lw=1.0, label='model')
    fcnDefaultAxisStyle(ax)
    ax.grid(True, which='both', linestyle='--', linewidth=0.1, color='k')
    ax.set_xlabel('Čas [s]', ha='left', va='top')
    ax.xaxis.set_label_coords(1.05, -0.07, transform=ax.transAxes)
    ax.set_ylabel(r'$\Delta y$ [-]', ha='right', va='bottom', rotation=0)
    ax.yaxis.set_label_coords(-0.07, 1.05, transform=ax.transAxes)
    ax.legend(loc='best', frameon=False)
    ax.set_title(title)

# ===== Subploty =====
ax0 = plt.subplot(subPlots[0, 0])
plot_subplot(ax0, t, y13_data, y3n_model, 'Ventilátor = 3 — snímač 1 (blízky)')

ax1 = plt.subplot(subPlots[0, 1])
plot_subplot(ax1, t, y23_data, y3f_model, 'Ventilátor = 3 — snímač 2 (vzdialený)')

ax2 = plt.subplot(subPlots[1, 0])
plot_subplot(ax2, t, y16_data, y6n_model, 'Ventilátor = 6 — snímač 1 (blízky)')

ax3 = plt.subplot(subPlots[1, 1])
plot_subplot(ax3, t, y26_data, y6f_model, 'Ventilátor = 6 — snímač 2 (vzdialený)')

ax4 = plt.subplot(subPlots[2, 0])
plot_subplot(ax4, t, y19_data, y9n_model, 'Ventilátor = 9 — snímač 1 (blízky)')

ax5 = plt.subplot(subPlots[2, 1])
plot_subplot(ax5, t, y29_data, y9f_model, 'Ventilátor = 9 — snímač 2 (vzdialený)')

# ===== Úprava rozloženia =====
fcnDefaultLayoutAdj(fig, figPlotParam[2], figPlotParam[3],
                    figPlotParam[4], figPlotParam[5])

# ===== Uloženie obrázka =====
plt.savefig(os.path.join(figSaveDir, f"{figName}.png"),
            dpi=300, bbox_inches='tight')
plt.close()

print(f"Obrázok uložený do {os.path.join(figSaveDir, figName + '.png')}")
