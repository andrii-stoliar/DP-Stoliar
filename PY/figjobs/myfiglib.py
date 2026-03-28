# -*- coding: utf-8 -*-

import matplotlib as mpl
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec

from matplotlib.ticker import AutoMinorLocator

# =============================================================================
# USAGE GUIDE
# =============================================================================
#
# Class: StackedFigure
#
# Purpose:
#   Create vertically stacked time-series plots with unified style.
#
# -----------------------------------------------------------------------------
# Constructor
# -----------------------------------------------------------------------------
#
# StackedFigure(height_cm, nrows=1, height_ratios=None)
#
# Arguments:
#   height_cm (float)
#       Total figure height in centimeters.
#
#   nrows (int, optional)
#       Number of stacked subplots (default: 1).
#
#   height_ratios (list of floats, optional)
#       Relative heights of subplots.
#       Example: [2, 1, 1] → first subplot is twice as tall.
#
# -----------------------------------------------------------------------------
# Method: panel()
# -----------------------------------------------------------------------------
#
# panel(i, xlabel="", ylabel="", title="", xlim=None, ylim=None)
#
# Purpose:
#   Configure axis labels, title, and limits for subplot i.
#
# Arguments:
#   i (int)
#       Index of subplot (0-based).
#
#   xlabel (str, optional)
#       Label for x-axis.
#
#   ylabel (str, optional)
#       Label for y-axis.
#
#   title (str, optional)
#       Title of subplot.
#
#   xlim (tuple, optional)
#       (xmin, xmax) axis limits.
#
#   ylim (tuple, optional)
#       (ymin, ymax) axis limits.
#
# -----------------------------------------------------------------------------
# Method: line()
# -----------------------------------------------------------------------------
#
# line(i, x, y, ls="-", lw=0.6, color="k", label=None)
#
# Purpose:
#   Plot a line on subplot i.
#
# Arguments:
#   i (int)
#       Index of subplot (0-based).
#
#   x (array-like)
#       X data.
#
#   y (array-like)
#       Y data.
#
#   ls (str, optional)
#       Line style ("-", "--", ":", etc.).
#
#   lw (float, optional)
#       Line width.
#
#   color (str, optional)
#       Line color (e.g. "k", "tab:blue").
#
#   label (str, optional)
#       Label for legend.
#       If None → no legend entry.
#
# -----------------------------------------------------------------------------
# Method: save()
# -----------------------------------------------------------------------------
#
# save(path, dpi=600)
#
# Purpose:
#   Save figure to file.
#
# Arguments:
#   path (str)
#       Output file path.
#
#   dpi (int, optional)
#       Resolution in dots per inch.
#
# -----------------------------------------------------------------------------
# INTERNAL BEHAVIOR (automatic)
# -----------------------------------------------------------------------------
#
# - Figure width is fixed (plot area = 13 cm)
# - Subplots are stacked vertically only
# - Axis styling (grid, spines, ticks) is applied automatically
# - Legends are created automatically if labels are provided
# - Axis limits are auto-scaled unless explicitly specified
# - TeX rendering is enabled for all text
#
# -----------------------------------------------------------------------------

# ============================================================================
# GLOBAL STYLE CONSTANTS (EDIT ONLY HERE)
# ============================================================================

# Plot area width (not full figure width)
PLOT_WIDTH_CM = 13.0

# Side padding (relative)
LR_PADDING = 0.17

# Vertical spacing between subplots
HSPACE = 0.40

# Absolute margins (in cm)
TOP_MARGIN_CM = 0.20
BOTTOM_MARGIN_CM = 0.60

# Axis label positions (relative to axes)
X_LABEL_COORDS = (1.05, -0.00)
Y_LABEL_COORDS = (-0.07, 1.03)

# Title position
TITLE_COORDS = (0.0, 1.03)

# Legend placement
LEGEND_ANCHOR = (1.01, 1.00)
LEGEND_FONTSIZE = 8

# Grid style
GRID_MAJOR_COLOR = "#cfcfcf"
GRID_MINOR_COLOR = "#e3e3e3"
GRID_MAJOR_LINEWIDTH = 0.33
GRID_MINOR_LINEWIDTH = 0.28
GRID_MAJOR_STYLE = "--"
GRID_MINOR_STYLE = ":"

DEFAULT_DPI = 600


# ============================================================================
# INTERNAL SETUP
# ============================================================================

def _apply_tex_style():
    mpl.rcParams["figure.dpi"] = 300
    mpl.rcParams["savefig.facecolor"] = "w"

    mpl.rcParams["font.size"] = 10
    mpl.rcParams["font.family"] = "serif"

    mpl.rcParams["text.usetex"] = True
    mpl.rcParams["text.latex.preamble"] = (
        r"\usepackage[T1]{fontenc} \usepackage{lmodern}"
    )

    mpl.rcParams["xtick.direction"] = "out"
    mpl.rcParams["ytick.direction"] = "out"

    mpl.rcParams["xtick.labelsize"] = mpl.rcParams["font.size"]
    mpl.rcParams["ytick.labelsize"] = mpl.rcParams["font.size"]

    mpl.rcParams["axes.xmargin"] = 0.01
    mpl.rcParams["axes.ymargin"] = 0.03

    mpl.rcParams["axes.titlesize"] = mpl.rcParams["font.size"]
    mpl.rcParams["axes.labelsize"] = mpl.rcParams["font.size"]

    mpl.rcParams["legend.fontsize"] = mpl.rcParams["font.size"]
    mpl.rcParams["legend.frameon"] = False
    mpl.rcParams["legend.borderpad"] = 0.1
    mpl.rcParams["legend.borderaxespad"] = 0.0
    mpl.rcParams["legend.labelspacing"] = 0.2
    mpl.rcParams["legend.numpoints"] = 1


def _cm_to_inch(value_cm):
    return value_cm / 2.54


def _compute_total_width_cm():
    usable = 1.0 - 2.0 * LR_PADDING
    return PLOT_WIDTH_CM / usable


# ============================================================================
# MAIN CLASS
# ============================================================================

class StackedFigure:
    def __init__(self, height_cm, nrows=1, height_ratios=None):
        _apply_tex_style()

        if height_ratios is None:
            height_ratios = [1] * nrows

        self.height_cm = float(height_cm)
        self.width_cm = _compute_total_width_cm()

        self.fig = plt.figure(
            figsize=(
                _cm_to_inch(self.width_cm),
                _cm_to_inch(self.height_cm)
            )
        )

        self.grid = gridspec.GridSpec(
            nrows,
            1,
            height_ratios=height_ratios,
            figure=self.fig
        )

        self.axes = [self.fig.add_subplot(self.grid[i, 0]) for i in range(nrows)]

        self._apply_layout()
        self._apply_style()

    # ----------------------------------------------------------------------

    def _apply_layout(self):
        top = 1.0 - TOP_MARGIN_CM / self.height_cm
        bottom = BOTTOM_MARGIN_CM / self.height_cm

        self.fig.subplots_adjust(
            left=LR_PADDING,
            right=1.0 - LR_PADDING,
            top=top,
            bottom=bottom,
            hspace=HSPACE
        )

    # ----------------------------------------------------------------------

    def _apply_style(self):
        for ax in self.axes:
            ax.spines["top"].set_visible(False)
            ax.spines["right"].set_visible(False)

            ax.get_xaxis().tick_bottom()
            ax.get_yaxis().tick_left()

            ax.xaxis.set_minor_locator(AutoMinorLocator())
            ax.yaxis.set_minor_locator(AutoMinorLocator())

            ax.ticklabel_format(axis="y", useOffset=False)

            ax.grid(
                which="major",
                color=GRID_MAJOR_COLOR,
                linewidth=GRID_MAJOR_LINEWIDTH,
                linestyle=GRID_MAJOR_STYLE
            )

            ax.grid(
                which="minor",
                color=GRID_MINOR_COLOR,
                linewidth=GRID_MINOR_LINEWIDTH,
                linestyle=GRID_MINOR_STYLE
            )

            ax.set_axisbelow(True)

    # ----------------------------------------------------------------------

    def panel(self, i, xlabel="", ylabel="", title="", xlim=None, ylim=None):
        ax = self.axes[i]

        ax.set_xlabel(xlabel, ha="left", va="top")
        ax.xaxis.set_label_coords(*X_LABEL_COORDS, transform=ax.transAxes)

        ax.set_ylabel(ylabel, ha="right", va="bottom", rotation=90)
        ax.yaxis.set_label_coords(*Y_LABEL_COORDS, transform=ax.transAxes)

        ax.set_title(
            title,
            ha="left",
            va="bottom",
            x=TITLE_COORDS[0],
            y=TITLE_COORDS[1]
        )

        if xlim:
            ax.set_xlim(*xlim)
        if ylim:
            ax.set_ylim(*ylim)

    # ----------------------------------------------------------------------

    def line(
        self,
        i,
        x,
        y,
        ls="-",
        lw=0.6,
        color="k",
        label=None,
        marker=None,
        ms=None
    ):
        ax = self.axes[i]

        kwargs = dict(
            linestyle=ls,
            linewidth=lw,
            color=color
        )

        if label is not None:
            kwargs["label"] = label

        if marker is not None:
            kwargs["marker"] = marker

        if ms is not None:
            kwargs["markersize"] = ms

        ax.plot(x, y, **kwargs)

    # ----------------------------------------------------------------------

    def _apply_legends(self):
        for ax in self.axes:
            handles, labels = ax.get_legend_handles_labels()
            if handles:
                ax.legend(
                    handles,
                    labels,
                    loc="upper left",
                    bbox_to_anchor=LEGEND_ANCHOR,
                    frameon=False,
                    fontsize=LEGEND_FONTSIZE,
                    handlelength=0.8
                )

    # ----------------------------------------------------------------------

    def save(self, path, dpi=DEFAULT_DPI):
        self._apply_layout()
        self._apply_legends()
        self.fig.savefig(path, dpi=dpi, bbox_inches=None, pad_inches=0.0)
        plt.close(self.fig)