# ============================================================
# Nyx Standard Library - Visualization Module
# ============================================================
# Comprehensive visualization library providing plotting and 
# charting capabilities equivalent to matplotlib, seaborn, 
# and plotly in Python.

# ============================================================
# Color Palettes and Schemes
# ============================================================

# Named colors
let COLORS = {
    "aliceblue": "#F0F8FF",
    "antiquewhite": "#FAEBD7",
    "aqua": "#00FFFF",
    "aquamarine": "#7FFFD4",
    "azure": "#F0FFFF",
    "beige": "#F5F5DC",
    "bisque": "#FFE4C4",
    "black": "#000000",
    "blanchedalmond": "#FFEBCD",
    "blue": "#0000FF",
    "blueviolet": "#8A2BE2",
    "brown": "#A52A2A",
    "burlywood": "#DEB887",
    "cadetblue": "#5F9EA0",
    "chartreuse": "#7FFF00",
    "chocolate": "#D2691E",
    "coral": "#FF7F50",
    "cornflowerblue": "#6495ED",
    "cornsilk": "#FFF8DC",
    "crimson": "#DC143C",
    "cyan": "#00FFFF",
    "darkblue": "#00008B",
    "darkcyan": "#008B8B",
    "darkgoldenrod": "#B8860B",
    "darkgray": "#A9A9A9",
    "darkgreen": "#006400",
    "darkgrey": "#A9A9A9",
    "darkkhaki": "#BDB76B",
    "darkmagenta": "#8B008B",
    "darkolivegreen": "#556B2F",
    "darkorange": "#FF8C00",
    "darkorchid": "#9932CC",
    "darkred": "#8B0000",
    "darksalmon": "#E9967A",
    "darkseagreen": "#8FBC8F",
    "darkslateblue": "#483D8B",
    "darkslategray": "#2F4F4F",
    "darkslategrey": "#2F4F4F",
    "darkturquoise": "#00CED1",
    "darkviolet": "#9400D3",
    "deeppink": "#FF1493",
    "deepskyblue": "#00BFFF",
    "dimgray": "#696969",
    "dimgrey": "#696969",
    "dodgerblue": "#1E90FF",
    "firebrick": "#B22222",
    "floralwhite": "#FFFAF0",
    "forestgreen": "#228B22",
    "fuchsia": "#FF00FF",
    "gainsboro": "#DCDCDC",
    "ghostwhite": "#F8F8FF",
    "gold": "#FFD700",
    "goldenrod": "#DAA520",
    "gray": "#808080",
    "green": "#008000",
    "greenyellow": "#ADFF2F",
    "grey": "#808080",
    "honeydew": "#F0FFF0",
    "hotpink": "#FF69B4",
    "indianred": "#CD5C5C",
    "indigo": "#4B0082",
    "ivory": "#FFFFF0",
    "khaki": "#F0E68C",
    "lavender": "#E6E6FA",
    "lavenderblush": "#FFF0F5",
    "lawngreen": "#7CFC00",
    "lemonchiffon": "#FFFACD",
    "lightblue": "#ADD8E6",
    "lightcoral": "#F08080",
    "lightcyan": "#E0FFFF",
    "lightgoldenrodyellow": "#FAFAD2",
    "lightgray": "#D3D3D3",
    "lightgreen": "#90EE90",
    "lightgrey": "#D3D3D3",
    "lightpink": "#FFB6C1",
    "lightsalmon": "#FFA07A",
    "lightseagreen": "#20B2AA",
    "lightskyblue": "#87CEFA",
    "lightslategray": "#778899",
    "lightslategrey": "#778899",
    "lightsteelblue": "#B0C4DE",
    "lightyellow": "#FFFFE0",
    "lime": "#00FF00",
    "limegreen": "#32CD32",
    "linen": "#FAF0E6",
    "magenta": "#FF00FF",
    "maroon": "#800000",
    "mediumaquamarine": "#66CDAA",
    "mediumblue": "#0000CD",
    "mediumorchid": "#BA55D3",
    "mediumpurple": "#9370DB",
    "mediumseagreen": "#3CB371",
    "mediumslateblue": "#7B68EE",
    "mediumspringgreen": "#00FA9A",
    "mediumturquoise": "#48D1CC",
    "mediumvioletred": "#C71585",
    "midnightblue": "#191970",
    "mintcream": "#F5FFFA",
    "mistyrose": "#FFE4E1",
    "moccasin": "#FFE4B5",
    "navajowhite": "#FFDEAD",
    "navy": "#000080",
    "oldlace": "#FDF5E6",
    "olive": "#808000",
    "olivedrab": "#6B8E23",
    "orange": "#FFA500",
    "orangered": "#FF4500",
    "orchid": "#DA70D6",
    "palegoldenrod": "#EEE8AA",
    "palegreen": "#98FB98",
    "paleturquoise": "#AFEEEE",
    "palevioletred": "#DB7093",
    "papayawhip": "#FFEFD5",
    "peachpuff": "#FFDAB9",
    "peru": "#CD853F",
    "pink": "#FFC0CB",
    "plum": "#DDA0DD",
    "powderblue": "#B0E0E6",
    "purple": "#800080",
    "rebeccapurple": "#663399",
    "red": "#FF0000",
    "rosybrown": "#BC8F8F",
    "royalblue": "#4169E1",
    "saddlebrown": "#8B4513",
    "salmon": "#FA8072",
    "sandybrown": "#F4A460",
    "seagreen": "#2E8B57",
    "seashell": "#FFF5EE",
    "sienna": "#A0522D",
    "silver": "#C0C0C0",
    "skyblue": "#87CEEB",
    "slateblue": "#6A5ACD",
    "slategray": "#708090",
    "slategrey": "#708090",
    "snow": "#FFFAFA",
    "springgreen": "#00FF7F",
    "steelblue": "#4682B4",
    "tan": "#D2B48C",
    "teal": "#008080",
    "thistle": "#D8BFD8",
    "tomato": "#FF6347",
    "turquoise": "#40E0D0",
    "violet": "#EE82EE",
    "wheat": "#F5DEB3",
    "white": "#FFFFFF",
    "whitesmoke": "#F5F5F5",
    "yellow": "#FFFF00",
    "yellowgreen": "#9ACD32"
};

# Colorbrewer palettes
let COLOR_PALETTES = {
    "accent": ["#7FC97F", "#BEAED4", "#FDC086", "#FFFF99", "#386CB0", "#F0027F", "#BF5B17", "#666666"],
    "dark2": ["#1B9E77", "#D95F02", "#7570B3", "#E7298A", "#66A61E", "#E6AB02", "#A6761D", "#666666"],
    "paired": ["#A6CEE3", "#1F78B4", "#B2DF8A", "#33A02C", "#FB9A99", "#E31A1C", "#FDBF6F", "#FF7F00", "#CAB2D6", "#6A3D9A", "#FFFF99", "#B15928"],
    "pastel1": ["#B3E2CD", "#FDCDAC", "#CBD5E8", "#F4CAE4", "#E6F5C9", "#FFF2AE", "#F1E2CC", "#CCCCCC"],
    "pastel2": ["#B3E2CD", "#FDCDAC", "#CBD5E8", "#F4CAE4", "#E6F5C9", "#FFF2AE", "#F1E2CC", "#CCCCCC"],
    "set1": ["#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00", "#FFFF33", "#A65628", "#F781BF", "#999999"],
    "set2": ["#66C2A5", "#FC8D62", "#8DA0CB", "#E78AC3", "#A6D854", "#FFD92F", "#E5C494", "#B3B3B3"],
    "set3": ["#8DD3C7", "#FFFFB3", "#BEBADA", "#FB8072", "#80B1D3", "#FDB462", "#B3DE69", "#FCCDE5", "#D9D9D9", "#BC80BD", "#CCEBC5", "#FFED6F"],
    "spectral": ["#9E0142", "#F46D43", "#FDAE61", "#FEE08B", "#E6F598", "#66C2A5", "#5E4FA2"]
};

# Color maps (gradient maps)
let COLOR_MAPS = {
    "viridis": ["#440154", "#482777", "#3F4A8A", "#31678E", "#26838F", "#1F9D8A", "#6CCE5A", "#B6DE2B", "#FEE825"],
    "plasma": ["#0D0887", "#6A00A8", "#B12A90", "#E16462", "#FCA636", "#F0F921"],
    "inferno": ["#000004", "#420A68", "#932667", "#DD513A", "#FCA50A", "#FCFFA4"],
    "magma": ["#000004", "#3B0F70", "#8C2981", "#DE4968", "#FE9F6D", "#FCFDBF"],
    "cividis": ["#00224E", "#123570", "#3B496C", "#575D6D", "#707880", "#A5AFBD", "#D4D7DB", "#F1F1F1"],
    "coolwarm": ["#3B4CC0", "#6788EE", "#9CBBF7", "#C9DBFB", "#FFFFFF", "#FAD2D2", "#F2989D", "#E06970", "#B40426"],
    "RdBu": ["#B40426", "#E06970", "#F2989D", "#FAD2D2", "#FFFFFF", "#C9DBFB", "#9CBBF7", "#6788EE", "#3B4CC0"],
    "PiYG": ["#8E2646", "#E6689C", "#F7A1C4", "#FDC7D2", "#FFFFFF", "#C7E5D6", "#8BD6A8", "#5AC08D", "#1A7F4E"],
    "PRGn": ["#400778", "#784C9C", "#AE82BF", "#D6BAD0", "#FFFFFF", "#C5E2C8", "#8BC1A7", "#5C9C83", "#0C6B4D"],
    "brbg": ["#543005", "#8C4B2D", "#BC8A5D", "#DDB892", "#F0E3C5", "#C5D8C5", "#9AC1A5", "#6BA284", "#1F7858"],
    "twilight": ["#6A247C", "#9C3C7E", "#CC517A", "#E66A71", "#F4875F", "#F9A663", "#F9C86E", "#E8D78A", "#D6DFA8", "#C3DDB0", "#BAD6AA", "#A6C7B0", "#94B5B2", "#829EAF", "#7085AC", "#5E6CA0"],
    "hsv": ["#FF0000", "#FF7F00", "#FFFF00", "#00FF00", "#00FFFF", "#0000FF", "#8B00FF", "#FF00FF", "#FF0000"]
};

# ============================================================
# Style Configuration
# ============================================================

let default_style = {
    "figure.figsize": [8, 6],
    "figure.dpi": 100,
    "figure.facecolor": "white",
    "axes.facecolor": "white",
    "axes.edgecolor": "black",
    "axes.linewidth": 1.0,
    "axes.grid": true,
    "axes.spines.top": true,
    "axes.spines.right": true,
    "axes.labelsize": 10,
    "axes.titlesize": 12,
    "axes.titleweight": "normal",
    "xtick.labelsize": 8,
    "ytick.labelsize": 8,
    "legend.fontsize": 10,
    "legend.frameon": true,
    "legend.framealpha": 0.8,
    "legend.fancybox": true,
    "lines.linewidth": 1.5,
    "lines.markersize": 6,
    "grid.alpha": 0.3,
    "grid.linestyle": "--",
    "grid.linewidth": 0.5,
    "font.family": "sans-serif",
    "font.size": 10,
    "savefig.dpi": 100,
    "savefig.format": "png",
    "savefig.bbox": "tight",
    "animation.html": "jshtml",
    "animation.writer": "pillow"
};

let current_style = { ...default_style };

# ============================================================
# Figure Class
# ============================================================

class Figure {
    init(figsize, dpi, facecolor) {
        self.figsize = figsize || [8, 6];
        self.dpi = dpi || 100;
        self.facecolor = facecolor || "white";
        self.axes = [];
        self.suptitle = null;
        self.layout = "auto";
        self.tight_layout = false;
        self._canvas_width = self.figsize[0] * self.dpi;
        self._canvas_height = self.figsize[1] * self.dpi;
    }

    add_axes(rect, projection) {
        let ax = Axes.new(self, rect, projection);
        self.axes.push(ax);
        return ax;
    }

    subplots(nrows, ncols, sharex, sharey, squeeze, subplot_kw) {
        nrows = nrows || 1;
        ncols = ncols || 1;
        sharex = sharex || false;
        sharey = sharey || false;
        squeeze = squeeze !== false;
        
        let axes_list = [];
        let width = 1.0 / ncols;
        let height = 1.0 / nrows;
        let padding = 0.05;
        
        for let row in range(nrows) {
            let row_axes = [];
            for let col in range(ncols) {
                let left = col * width + padding / 2;
                let bottom = 1.0 - (row + 1) * height + padding / 2;
                let rect = [left, bottom, width - padding, height - padding];
                let ax = self.add_axes(rect);
                row_axes.push(ax);
            }
            if squeeze && nrows == 1 {
                axes_list.push(row_axes[0]);
            } else if squeeze && ncols == 1 {
                axes_list.push(row_axes[0]);
            } else {
                axes_list.push(row_axes);
            }
        }
        
        if squeeze && nrows == 1 && ncols == 1 {
            return axes_list[0];
        }
        return axes_list;
    }

    suptitle(title, fontsize, fontweight, pad) {
        self.suptitle = {
            "title": title,
            "fontsize": fontsize || 12,
            "fontweight": fontweight || "normal",
            "pad": pad || 20
        };
    }

    legend(loc, fontsize, frameon, title) {
        let handles = [];
        let labels = [];
        for let ax in self.axes {
            for let handle in ax._legend_handles {
                handles.push(handle[0]);
                labels.push(handle[1]);
            }
        }
        
        if len(handles) == 0 {
            return null;
        }
        
        return {
            "handles": handles,
            "labels": labels,
            "loc": loc || "best",
            "fontsize": fontsize || 10,
            "frameon": frameon !== false,
            "title": title || null
        };
    }

    savefig(filename, dpi, bbox_inches, format, facecolor, edgecolor) {
        let export_dpi = dpi || self.dpi;
        let export_format = format || "png";
        
        return {
            "filename": filename,
            "dpi": export_dpi,
            "format": export_format,
            "bbox_inches": bbox_inches || "tight",
            "facecolor": facecolor || self.facecolor,
            "edgecolor": edgecolor || "none",
            "width": self.figsize[0] * export_dpi,
            "height": self.figsize[1] * export_dpi
        };
    }

    show() {
        # Render the figure for display
        let output = {
            "type": "figure",
            "figsize": self.figsize,
            "dpi": self.dpi,
            "axes": [],
            "suptitle": self.suptitle
        };
        
        for let ax in self.axes {
            output.axes.push(ax._serialize());
        }
        
        return output;
    }

    close() {
        self.axes = [];
        self.suptitle = null;
    }
}

# ============================================================
# Axes Class
# ============================================================

class Axes {
    init(fig, rect, projection) {
        self.figure = fig;
        self.position = rect;  # [left, bottom, width, height]
        self.projection = projection || "2d";
        
        # Data limits
        self._xlim = [0, 1];
        self._ylim = [0, 1];
        self._zlim = [0, 1];
        
        # Labels and title
        self._xlabel = "";
        self._ylabel = "";
        self._zlabel = "";
        self._title = "";
        
        # Grid
        self._grid = true;
        self._grid_alpha = 0.3;
        self._grid_linestyle = "--";
        
        # Axis properties
        self._xscale = "linear";
        self._yscale = "linear";
        self._zscale = "linear";
        
        # Ticks
        self._xticks = null;
        self._yticks = null;
        self._zticks = null;
        self._xticklabels = null;
        self._yticklabels = null;
        self._zticklabels = null;
        
        # Spines
        self._spines = {
            "top": true,
            "bottom": true,
            "left": true,
            "right": true
        };
        
        # Data storage
        self._artists = [];
        self._lines = [];
        self._patches = [];
        self._collections = [];
        self._texts = [];
        self._legend_handles = [];
        
        # Color cycle
        self._color_index = 0;
        
        # Aspect ratio
        self._aspect = "auto";
        
        # Secondary axes
        self._twiny = null;
        self._twiny_axes = null;
        self._twinx = null;
        self._twinx_axes = null;
    }

    _get_next_color() {
        let colors = COLOR_PALETTES["set1"];
        let color = colors[self._color_index % len(colors)];
        self._color_index = self._color_index + 1;
        return color;
    }

    set_xlim(left, right, emit) {
        if type(left) == "list" && len(left) == 2 {
            self._xlim = left;
        } else {
            self._xlim = [left, right];
        }
    }

    set_ylim(bottom, top, emit) {
        if type(bottom) == "list" && len(bottom) == 2 {
            self._ylim = bottom;
        } else {
            self._ylim = [bottom, top];
        }
    }

    set_zlim(bottom, top, emit) {
        if type(bottom) == "list" && len(bottom) == 2 {
            self._zlim = bottom;
        } else {
            self._zlim = [bottom, top];
        }
    }

    get_xlim() {
        return self._xlim;
    }

    get_ylim() {
        return self._ylim;
    }

    get_zlim() {
        return self._zlim;
    }

    set_xscale(scale) {
        self._xscale = scale;
    }

    set_yscale(scale) {
        self._yscale = scale;
    }

    set_zscale(scale) {
        self._zscale = scale;
    }

    set_xlabel(label, fontsize, fontweight, labelpad) {
        self._xlabel = label;
    }

    set_ylabel(label, fontsize, fontweight, labelpad) {
        self._ylabel = label;
    }

    set_zlabel(label, fontsize, fontweight, labelpad) {
        self._zlabel = label;
    }

    set_title(label, fontsize, fontweight, loc, pad) {
        self._title = label;
    }

    set_aspect(aspect) {
        self._aspect = aspect;
    }

    set_axis_on() {
        self._axis_on = true;
    }

    set_axis_off() {
        self._axis_on = false;
    }

    grid(b, which, axis, linestyle, linewidth, color, alpha) {
        self._grid = b !== false;
        self._grid_linestyle = linestyle || "--";
        self._grid_linewidth = linewidth || 0.5;
        self._grid_color = color || "gray";
        self._grid_alpha = alpha || 0.3;
    }

    tick_params(axis, which, direction, length, width, color, labelsize) {
        # Configure tick parameters
    }

    # ----- Plotting Methods -----

    plot(x, y, fmt, label, linewidth, linestyle, marker, markersize, color, alpha) {
        if type(x) != "list" {
            x = [x];
        }
        if type(y) != "list" {
            y = [y];
        }
        
        let line_color = color || self._get_next_color();
        let line_style = linestyle || "-";
        let line_width = linewidth || 1.5;
        let marker_style = marker || "none";
        let marker_size = markersize || 6;
        
        let line_data = {
            "type": "line",
            "x": x,
            "y": y,
            "color": line_color,
            "linestyle": line_style,
            "linewidth": line_width,
            "marker": marker_style,
            "markersize": marker_size,
            "alpha": alpha || 1.0,
            "label": label || ""
        };
        
        self._lines.push(line_data);
        self._artists.push(line_data);
        
        if label && label != "" {
            self._legend_handles.push([line_data, label]);
        }
        
        # Auto-update limits
        self._update_limits(x, y);
        
        return [line_data];
    }

    scatter(x, y, s, c, marker, cmap, alpha, edgecolors, linewidths, label) {
        if type(x) != "list" {
            x = [x];
        }
        if type(y) != "list" {
            y = [y];
        }
        
        # Handle size
        if type(s) == "number" {
            s = s;
        } else if type(s) == "list" {
            s = s;
        } else {
            s = 50;
        }
        
        # Handle color
        let colors = c;
        if type(c) == "string" {
            colors = c;
        } else if type(c) == "list" {
            colors = c;
        } else {
            colors = self._get_next_color();
        }
        
        let scatter_data = {
            "type": "scatter",
            "x": x,
            "y": y,
            "s": s,
            "c": colors,
            "marker": marker || "o",
            "cmap": cmap || "viridis",
            "alpha": alpha || 1.0,
            "edgecolors": edgecolors || "face",
            "linewidths": linewidths || 0.5,
            "label": label || ""
        };
        
        self._collections.push(scatter_data);
        self._artists.push(scatter_data);
        
        if label && label != "" {
            self._legend_handles.push([scatter_data, label]);
        }
        
        self._update_limits(x, y);
        
        return [scatter_data];
    }

    bar(x, height, width, bottom, align, color, edgecolor, linewidth, label, alpha) {
        width = width || 0.8;
        bottom = bottom || 0;
        align = align || "center";
        color = color || self._get_next_color();
        
        let bar_data = {
            "type": "bar",
            "x": x,
            "height": height,
            "width": width,
            "bottom": bottom,
            "align": align,
            "color": color,
            "edgecolor": edgecolor || "black",
            "linewidth": linewidth || 1,
            "label": label || "",
            "alpha": alpha || 1.0
        };
        
        self._patches.push(bar_data);
        self._artists.push(bar_data);
        
        if label && label != "" {
            self._legend_handles.push([bar_data, label]);
        }
        
        # Update limits
        let y_max = bottom + max(height);
        if self._ylim[1] < y_max {
            self._ylim[1] = y_max;
        }
        
        return [bar_data];
    }

    barh(y, width, height, left, align, color, edgecolor, linewidth, label, alpha) {
        height = height || 0.8;
        left = left || 0;
        align = align || "center";
        color = color || self._get_next_color();
        
        let barh_data = {
            "type": "barh",
            "y": y,
            "width": width,
            "height": height,
            "left": left,
            "align": align,
            "color": color,
            "edgecolor": edgecolor || "black",
            "linewidth": linewidth || 1,
            "label": label || "",
            "alpha": alpha || 1.0
        };
        
        self._patches.push(barh_data);
        self._artists.push(barh_data);
        
        if label && label != "" {
            self._legend_handles.push([barh_data, label]);
        }
        
        # Update limits
        let x_max = left + max(width);
        if self._xlim[1] < x_max {
            self._xlim[1] = x_max;
        }
        
        return [barh_data];
    }

    hist(x, bins, range, density, cumulative, bottom, histtype, align, orientation, rwidth, color, edgecolor, label, alpha) {
        bins = bins || 10;
        
        # Calculate histogram
        let min_val = min(x);
        let max_val = max(x);
        let range_val = range || [min_val, max_val];
        let bin_width = (range_val[1] - range_val[0]) / bins;
        
        let counts = [];
        let bin_edges = [];
        
        for let i in range(bins + 1) {
            bin_edges.push(range_val[0] + i * bin_width);
            counts.push(0);
        }
        
        for let val in x {
            if val >= range_val[0] && val <= range_val[1] {
                let bin_idx = int((val - range_val[0]) / bin_width);
                if bin_idx >= bins {
                    bin_idx = bins - 1;
                }
                counts[bin_idx] = counts[bin_idx] + 1;
            }
        }
        
        let bin_centers = [];
        for let i in range(bins) {
            bin_centers.push((bin_edges[i] + bin_edges[i + 1]) / 2);
        }
        
        let hist_data = {
            "type": "hist",
            "counts": counts,
            "bin_edges": bin_edges,
            "bin_centers": bin_centers,
            "bins": bins,
            "range": range_val,
            "density": density || false,
            "cumulative": cumulative || false,
            "histtype": histtype || "bar",
            "align": align || "mid",
            "orientation": orientation || "vertical",
            "color": color || self._get_next_color(),
            "edgecolor": edgecolor || "black",
            "label": label || "",
            "alpha": alpha || 1.0
        };
        
        self._patches.push(hist_data);
        self._artists.push(hist_data);
        
        if label && label != "" {
            self._legend_handles.push([hist_data, label]);
        }
        
        # Update limits
        if self._xlim[0] > range_val[0] {
            self._xlim[0] = range_val[0];
        }
        if self._xlim[1] < range_val[1] {
            self._xlim[1] = range_val[1];
        }
        let max_count = max(counts);
        if self._ylim[1] < max_count {
            self._ylim[1] = max_count * 1.1;
        }
        
        return [hist_data, counts, bin_edges];
    }

    boxplot(x, notch, vert, patch_artist, widths, labels, showmeans, meanprops, medianprops, whiskerprops, capprops, flierprops) {
        # Calculate boxplot statistics
        let sorted_x = [...x];
        sorted_x.sort();
        
        let n = len(sorted_x);
        let q1_idx = int(n * 0.25);
        let q2_idx = int(n * 0.5);
        let q3_idx = int(n * 0.75);
        
        let q1 = sorted_x[q1_idx];
        let median = sorted_x[q2_idx];
        let q3 = sorted_x[q3_idx];
        let iqr = q3 - q1;
        
        let whisker_low = q1 - 1.5 * iqr;
        let whisker_high = q3 + 1.5 * iqr;
        
        # Find actual whisker values
        let whisker_data_low = [];
        let whisker_data_high = [];
        let fliers = [];
        
        for let val in x {
            if val < whisker_low {
                fliers.push(val);
            } else if val > whisker_high {
                fliers.push(val);
            } else if val < q1 {
                whisker_data_low.push(val);
            } else if val > q3 {
                whisker_data_high.push(val);
            }
        }
        
        let box_data = {
            "type": "boxplot",
            "whisker_low": len(whisker_data_low) > 0 ? max(whisker_data_low) : whisker_low,
            "whisker_high": len(whisker_data_high) > 0 ? min(whisker_data_high) : whisker_high,
            "q1": q1,
            "median": median,
            "q3": q3,
            "fliers": fliers,
            "notch": notch || false,
            "vert": vert !== false,
            "patch_artist": patch_artist || false,
            "widths": widths || 0.5,
            "label": labels || "",
            "showmeans": showmeans || false,
            "color": self._get_next_color()
        };
        
        self._collections.push(box_data);
        self._artists.push(box_data);
        
        return [box_data];
    }

    violinplot(x, positions, widths, showmeans, showmedians, showextrema) {
        # Estimate kernel density for violin plot
        let sorted_x = [...x];
        sorted_x.sort();
        
        let n = len(sorted_x);
        let mean_val = 0;
        for let val in x {
            mean_val = mean_val + val;
        }
        mean_val = mean_val / n;
        
        let median_val = sorted_x[int(n * 0.5)];
        
        # Simple density estimation
        let density = [];
        let violin_x = [];
        let step = (max(x) - min(x)) / 20;
        
        for let i in range(21) {
            let v = min(x) + i * step;
            violin_x.push(v);
            
            # Gaussian kernel density estimate
            let d = 0;
            for let xi in x {
                d = d + exp(-0.5 * pow((v - xi) / (0.5 * step), 2));
            }
            density.push(d / n);
        }
        
        let violin_data = {
            "type": "violin",
            "x": x,
            "density": density,
            "violin_x": violin_x,
            "mean": mean_val,
            "median": median_val,
            "positions": positions || [1],
            "widths": widths || 0.9,
            "showmeans": showmeans || false,
            "showmedians": showmedians !== false,
            "showextrema": showextrema !== false,
            "color": self._get_next_color()
        };
        
        self._collections.push(violin_data);
        self._artists.push(violin_data);
        
        return [violin_data];
    }

    pie(x, labels, colors, explode, autopct, pctdistance, shadow, startangle, radius, center, wedgeprops) {
        let total = 0;
        for let val in x {
            total = total + val;
        }
        
        colors = colors || [];
        for let i in range(len(x) - len(colors)) {
            colors.push(self._get_next_color());
        }
        
        explode = explode || [];
        for let i in range(len(x) - len(explode)) {
            explode.push(0);
        }
        
        let slices = [];
        let start_angle = startangle || 0;
        
        for let i in range(len(x)) {
            let angle_span = (x[i] / total) * 360;
            let wedge = {
                "type": "pie_slice",
                "value": x[i],
                "percentage": (x[i] / total) * 100,
                "label": len(labels) > i ? labels[i] : "",
                "color": colors[i],
                "explode": explode[i],
                "start_angle": start_angle,
                "end_angle": start_angle + angle_span,
                "radius": radius || 1,
                "center": center || [0, 0],
                "autopct": autopct || "",
                "shadow": shadow || false
            };
            slices.push(wedge);
            start_angle = start_angle + angle_span;
        }
        
        self._collections.push({ "type": "pie", "slices": slices });
        self._artists.push({ "type": "pie", "slices": slices });
        
        return slices;
    }

    fill(x, y, color, alpha, label) {
        if type(x) != "list" {
            x = [x];
        }
        if type(y) != "list" {
            y = [y];
        }
        
        let fill_data = {
            "type": "fill",
            "x": x,
            "y": y,
            "color": color || self._get_next_color(),
            "alpha": alpha || 0.3,
            "label": label || ""
        };
        
        self._collections.push(fill_data);
        self._artists.push(fill_data);
        
        if label && label != "" {
            self._legend_handles.push([fill_data, label]);
        }
        
        return [fill_data];
    }

    fill_between(x, y1, y2, where, interpolate, step, color, alpha, label) {
        let fill_data = {
            "type": "fill_between",
            "x": x,
            "y1": y1,
            "y2": y2,
            "where": where || null,
            "interpolate": interpolate || false,
            "step": step || "pre",
            "color": color || self._get_next_color(),
            "alpha": alpha || 0.3,
            "label": label || ""
        };
        
        self._collections.push(fill_data);
        self._artists.push(fill_data);
        
        if label && label != "" {
            self._legend_handles.push([fill_data, label]);
        }
        
        return [fill_data];
    }

    step(x, y, where, fmt, label, linewidth, color, alpha) {
        where = where || "pre";
        
        let step_data = {
            "type": "step",
            "x": x,
            "y": y,
            "where": where,
            "color": color || self._get_next_color(),
            "linewidth": linewidth || 1.5,
            "alpha": alpha || 1.0,
            "label": label || ""
        };
        
        self._lines.push(step_data);
        self._artists.push(step_data);
        
        if label && label != "" {
            self._legend_handles.push([step_data, label]);
        }
        
        return [step_data];
    }

    stem(x, y, linefmt, markerfmt, basefmt, bottom, label, use_line_collection) {
        let stem_data = {
            "type": "stem",
            "x": x,
            "y": y,
            "linefmt": linefmt || "-",
            "markerfmt": markerfmt || "o",
            "basefmt": basefmt || "-",
            "bottom": bottom || 0,
            "label": label || "",
            "color": self._get_next_color()
        };
        
        self._lines.push(stem_data);
        self._artists.push(stem_data);
        
        if label && label != "" {
            self._legend_handles.push([stem_data, label]);
        }
        
        return [stem_data];
    }

    errorbar(x, y, yerr, xerr, fmt, ecolor, elinewidth, capsize, capthick, label, alpha) {
        let error_data = {
            "type": "errorbar",
            "x": x,
            "y": y,
            "yerr": yerr || null,
            "xerr": xerr || null,
            "fmt": fmt || "o",
            "ecolor": ecolor || "black",
            "elinewidth": elinewidth || 1.5,
            "capsize": capsize || 0,
            "capthick": capthick || 1,
            "label": label || "",
            "alpha": alpha || 1.0
        };
        
        self._lines.push(error_data);
        self._artists.push(error_data);
        
        if label && label != "" {
            self._legend_handles.push([error_data, label]);
        }
        
        self._update_limits(x, y);
        
        return [error_data];
    }

    contour(X, Y, Z, levels, colors, cmap, linewidths, linestyles, alpha) {
        # Generate contour lines
        let contour_data = {
            "type": "contour",
            "X": X,
            "Y": Y,
            "Z": Z,
            "levels": levels || 10,
            "colors": colors || null,
            "cmap": cmap || "viridis",
            "linewidths": linewidths || 1.0,
            "linestyles": linestyles || "solid",
            "alpha": alpha || 1.0
        };
        
        self._collections.push(contour_data);
        self._artists.push(contour_data);
        
        return [contour_data];
    }

    contourf(X, Y, Z, levels, colors, cmap, alpha, locator) {
        # Generate filled contour
        let contourf_data = {
            "type": "contourf",
            "X": X,
            "Y": Y,
            "Z": Z,
            "levels": levels || 10,
            "colors": colors || null,
            "cmap": cmap || "viridis",
            "alpha": alpha || 1.0
        };
        
        self._collections.push(contourf_data);
        self._artists.push(contourf_data);
        
        return [contourf_data];
    }

    # ----- 3D Plotting -----

    plot3D(x, y, z, fmt, label, linewidth, color, alpha) {
        if type(x) != "list" {
            x = [x];
        }
        if type(y) != "list" {
            y = [y];
        }
        if type(z) != "list" {
            z = [z];
        }
        
        let line3d_data = {
            "type": "line3d",
            "x": x,
            "y": y,
            "z": z,
            "color": color || self._get_next_color(),
            "linewidth": linewidth || 1.5,
            "label": label || "",
            "alpha": alpha || 1.0
        };
        
        self._lines.push(line3d_data);
        self._artists.push(line3d_data);
        
        if label && label != "" {
            self._legend_handles.push([line3d_data, label]);
        }
        
        # Update 3D limits
        self._update_limits_3d(x, y, z);
        
        return [line3d_data];
    }

    scatter3D(x, y, z, s, c, cmap, depthshade, alpha, label) {
        if type(x) != "list" {
            x = [x];
        }
        if type(y) != "list" {
            y = [y];
        }
        if type(z) != "list" {
            z = [z];
        }
        
        let scatter3d_data = {
            "type": "scatter3d",
            "x": x,
            "y": y,
            "z": z,
            "s": s || 50,
            "c": c || self._get_next_color(),
            "cmap": cmap || "viridis",
            "depthshade": depthshade !== false,
            "alpha": alpha || 1.0,
            "label": label || ""
        };
        
        self._collections.push(scatter3d_data);
        self._artists.push(scatter3d_data);
        
        if label && label != "" {
            self._legend_handles.push([scatter3d_data, label]);
        }
        
        self._update_limits_3d(x, y, z);
        
        return [scatter3d_data];
    }

    plot_surface(X, Y, Z, cmap, color, alpha, linewidth, antialiased) {
        let surface_data = {
            "type": "surface",
            "X": X,
            "Y": Y,
            "Z": Z,
            "cmap": cmap || "viridis",
            "color": color || null,
            "alpha": alpha || 1.0,
            "linewidth": linewidth || 0,
            "antialiased": antialiased !== false
        };
        
        self._collections.push(surface_data);
        self._artists.push(surface_data);
        
        return [surface_data];
    }

    plot_trisurf(x, y, z, cmap, color, alpha, linewidth) {
        let trisurf_data = {
            "type": "trisurf",
            "x": x,
            "y": y,
            "z": z,
            "cmap": cmap || "viridis",
            "color": color || null,
            "alpha": alpha || 1.0,
            "linewidth": linewidth || 0
        };
        
        self._collections.push(trisurf_data);
        self._artists.push(trisurf_data);
        
        return [trisurf_data];
    }

    bar3D(x, y, z, dx, dy, dz, color, alpha, shade) {
        let bar3d_data = {
            "type": "bar3d",
            "x": x,
            "y": y,
            "z": z,
            "dx": dx || 1,
            "dy": dy || 1,
            "dz": dz,
            "color": color || self._get_next_color(),
            "alpha": alpha || 1.0,
            "shade": shade !== false
        };
        
        self._collections.push(bar3d_data);
        self._artists.push(bar3d_data);
        
        return [bar3d_data];
    }

    # ----- Text and Annotations -----

    text(x, y, s, fontsize, fontweight, ha, va, rotation, wrap, transform, color, backgroundcolor, alpha, label) {
        let text_data = {
            "type": "text",
            "x": x,
            "y": y,
            "s": s,
            "fontsize": fontsize || 10,
            "fontweight": fontweight || "normal",
            "ha": ha || "left",
            "va": va || "bottom",
            "rotation": rotation || 0,
            "wrap": wrap || false,
            "transform": transform || "data",
            "color": color || "black",
            "backgroundcolor": backgroundcolor || null,
            "alpha": alpha || 1.0,
            "label": label || ""
        };
        
        self._texts.push(text_data);
        self._artists.push(text_data);
        
        return [text_data];
    }

    annotate(s, xy, xytext, textcoords, arrowprops, annotation_clip, fontdict) {
        let arrow_data = {
            "type": "annotation",
            "text": s,
            "xy": xy,
            "xytext": xytext || [xy[0] + 0.1, xy[1] + 0.1],
            "textcoords": textcoords || "data",
            "arrowprops": arrowprops || { "arrowstyle": "->" },
            "annotation_clip": annotation_clip || false,
            "fontdict": fontdict || {}
        };
        
        self._texts.push(arrow_data);
        self._artists.push(arrow_data);
        
        return [arrow_data];
    }

    title(label, fontsize, fontweight, loc, pad) {
        self._title = label;
    }

    xlabel(label, fontsize, fontweight, labelpad) {
        self._xlabel = label;
    }

    ylabel(label, fontsize, fontweight, labelpad) {
        self._ylabel = label;
    }

    zlabel(label, fontsize, fontweight, labelpad) {
        self._zlabel = label;
    }

    # ----- Limits and Scaling -----

    autoscale(enable, axis, tight) {
        # Auto-scale axis limits based on data
    }

    set_xlim(left, right) {
        if type(left) == "list" && len(left) == 2 {
            self._xlim = left;
        } else {
            self._xlim = [left, right];
        }
    }

    set_ylim(bottom, top) {
        if type(bottom) == "list" && len(bottom) == 2 {
            self._ylim = bottom;
        } else {
            self._ylim = [bottom, top];
        }
    }

    set_zlim(bottom, top) {
        if type(bottom) == "list" && len(bottom) == 2 {
            self._zlim = bottom;
        } else {
            self._zlim = [bottom, top];
        }
    }

    # ----- Ticks and Labels -----

    set_xticks(ticks, labels, fontsize, rotation) {
        self._xticks = ticks;
        self._xticklabels = labels;
    }

    set_yticks(ticks, labels, fontsize, rotation) {
        self._yticks = ticks;
        self._yticklabels = labels;
    }

    set_zticks(ticks, labels, fontsize, rotation) {
        self._zticks = ticks;
        self._zticklabels = labels;
    }

    xticks(ticks, labels, fontsize, rotation) {
        self.set_xticks(ticks, labels, fontsize, rotation);
    }

    yticklabels(labels, fontsize, rotation) {
        self.set_yticks(null, labels, fontsize, rotation);
    }

    # ----- Legend -----

    legend(loc, fontsize, frameon, title, ncol, shadow, fancybox) {
        return {
            "loc": loc || "best",
            "fontsize": fontsize || 10,
            "frameon": frameon !== false,
            "title": title || null,
            "ncol": ncol || 1,
            "shadow": shadow || false,
            "fancybox": fancybox !== false
        };
    }

    # ----- spines and axis -----

    spines() {
        return {
            "top": { "visible": self._spines.top },
            "bottom": { "visible": self._spines.bottom },
            "left": { "visible": self._spines.left },
            "right": { "visible": self._spines.right }
        };
    }

    # ----- Secondary axes -----

    twinx() {
        if self._twinx_axes {
            return self._twinx_axes;
        }
        
        let twin = Axes.new(self.figure, self.position, self.projection);
        twin._parent = self;
        twin._share_y = true;
        self._twinx_axes = twin;
        
        return twin;
    }

    twiny() {
        if self._twiny_axes {
            return self._twiny_axes;
        }
        
        let twin = Axes.new(self.figure, self.position, self.projection);
        twin._parent = self;
        twin._share_x = true;
        self._twiny_axes = twin;
        
        return twin;
    }

    # ----- Helper methods -----

    _update_limits(x, y) {
        if len(x) > 0 {
            let x_min = min(x);
            let x_max = max(x);
            if x_min < self._xlim[0] {
                self._xlim[0] = x_min;
            }
            if x_max > self._xlim[1] {
                self._xlim[1] = x_max;
            }
        }
        
        if len(y) > 0 {
            let y_min = min(y);
            let y_max = max(y);
            if y_min < self._ylim[0] {
                self._ylim[0] = y_min;
            }
            if y_max > self._ylim[1] {
                self._ylim[1] = y_max;
            }
        }
    }

    _update_limits_3d(x, y, z) {
        self._update_limits(x, y);
        
        if len(z) > 0 {
            let z_min = min(z);
            let z_max = max(z);
            if z_min < self._zlim[0] {
                self._zlim[0] = z_min;
            }
            if z_max > self._zlim[1] {
                self._zlim[1] = z_max;
            }
        }
    }

    _serialize() {
        return {
            "position": self.position,
            "projection": self.projection,
            "xlim": self._xlim,
            "ylim": self._ylim,
            "zlim": self._zlim,
            "xlabel": self._xlabel,
            "ylabel": self._ylabel,
            "zlabel": self._zlabel,
            "title": self._title,
            "xscale": self._xscale,
            "yscale": self._yscale,
            "zscale": self._zscale,
            "grid": self._grid,
            "artists": self._artists,
            "spines": self._spines
        };
    }
}

# ============================================================
# Style Management
# ============================================================

fn style(name) {
    let styles = {
        "default": {
            "axes.facecolor": "white",
            "axes.edgecolor": "black",
            "axes.linewidth": 1.0,
            "axes.grid": true,
            "grid.alpha": 0.3,
            "grid.linestyle": "--",
            "lines.linewidth": 1.5,
            "lines.markersize": 6
        },
        "ggplot": {
            "axes.facecolor": "#E5E5E5",
            "axes.edgecolor": "#FFFFFF",
            "axes.linewidth": 1.0,
            "axes.grid": true,
            "grid.alpha": 0.5,
            "grid.linestyle": "-",
            "lines.linewidth": 1.5,
            "lines.markersize": 6
        },
        "seaborn": {
            "axes.facecolor": "white",
            "axes.edgecolor": "#D0D0D0",
            "axes.linewidth": 1.0,
            "axes.grid": true,
            "grid.alpha": 0.3,
            "grid.linestyle": "--",
            "lines.linewidth": 1.5,
            "lines.markersize": 6
        },
        "dark_background": {
            "axes.facecolor": "#1E1E1E",
            "axes.edgecolor": "#FFFFFF",
            "axes.linewidth": 1.0,
            "axes.grid": true,
            "grid.alpha": 0.3,
            "grid.linestyle": "--",
            "lines.linewidth": 1.5,
            "lines.markersize": 6
        },
        "bmh": {
            "axes.facecolor": "#F0F0F0",
            "axes.edgecolor": "#000000",
            "axes.linewidth": 1.0,
            "axes.grid": true,
            "grid.alpha": 0.3,
            "grid.linestyle": "solid",
            "lines.linewidth": 1.5,
            "lines.markersize": 6
        },
        "fivethirtyeight": {
            "axes.facecolor": "white",
            "axes.edgecolor": "#000000",
            "axes.linewidth": 1.0,
            "axes.grid": false,
            "lines.linewidth": 2.0,
            "lines.markersize": 6
        },
        "grayscale": {
            "axes.facecolor": "white",
            "axes.edgecolor": "black",
            "axes.linewidth": 1.0,
            "axes.grid": true,
            "grid.alpha": 0.3,
            "lines.linewidth": 1.5,
            "lines.markersize": 6
        }
    };
    
    if styles[name] {
        current_style = { ...styles[name] };
    }
}

fn rc(params) {
    for let key in params {
        current_style[key] = params[key];
    }
}

fn rcdefaults() {
    current_style = { ...default_style };
}

# ============================================================
# Figure Management
# ============================================================

let _gcf_figure = null;

fn figure(num, figsize, dpi, facecolor, edgecolor, frameon) {
    if num !== null && num !== undefined {
        # Return existing figure if it exists
        for let i in range(len(_figure_list)) {
            if _figure_list[i] && _figure_list[i]._number == num {
                return _figure_list[i];
            }
        }
    }
    
    let fig = Figure.new(figsize, dpi, facecolor);
    fig._number = num || 1;
    _gcf_figure = fig;
    
    return fig;
}

fn gcf() {
    if _gcf_figure {
        return _gcf_figure;
    }
    return figure(1);
}

fn clf() {
    _gcf_figure = null;
}

fn close(fig) {
    if type(fig) == "number" {
        # Close specific figure
    } else if fig {
        # Close the figure
        if _gcf_figure == fig {
            _gcf_figure = null;
        }
    } else {
        # Close current figure
        _gcf_figure = null;
    }
}

# ============================================================
# Convenience Functions
# ============================================================

fn figure(figsize, dpi) {
    return Figure.new(figsize, dpi, "white");
}

fn subplots(nrows, ncols, sharex, sharey, squeeze, width_ratios, height_ratios) {
    let fig = Figure.new([6.4 * ncols, 4.8 * nrows], 100, "white");
    return fig.subplots(nrows, ncols, sharex, sharey, squeeze);
}

fn show() {
    let fig = gcf();
    return fig.show();
}

fn savefig(filename, dpi, bbox_inches, format) {
    let fig = gcf();
    return fig.savefig(filename, dpi, bbox_inches, format);
}

fn clf() {
    let fig = gcf();
    fig.close();
}

fn cla() {
    let fig = gcf();
    if len(fig.axes) > 0 {
        fig.axes[0]._artists = [];
        fig.axes[0]._lines = [];
        fig.axes[0]._collections = [];
        fig.axes[0]._patches = [];
        fig.axes[0]._texts = [];
        fig.axes[0]._legend_handles = [];
    }
}

# ============================================================
# Plot Type Functions
# ============================================================

fn plot(x, y, fmt) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    return ax.plot(x, y, fmt);
}

fn scatter(x, y, s, c, marker, cmap, alpha) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    return ax.scatter(x, y, s, c, marker, cmap, alpha);
}

fn bar(x, height, width, bottom, color, label) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    return ax.bar(x, height, width, bottom, "center", color, null, null, label);
}

fn barh(y, width, height, left, color, label) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    return ax.barh(y, width, height, left, "center", color, null, null, label);
}

fn hist(x, bins, range, density, cumulative, color, label, alpha) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    return ax.hist(x, bins, range, density, cumulative, null, "bar", "mid", "vertical", null, color, null, label, alpha);
}

fn boxplot(x, notch, vert, labels, showmeans) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    return ax.boxplot(x, notch, vert, false, null, labels, showmeans, null, null, null, null);
}

fn violinplot(x, positions, showmeans, showmedians) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    return ax.violinplot(x, positions, null, showmeans, showmedians, true);
}

fn pie(x, labels, colors, autopct, startangle) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    return ax.pie(x, labels, colors, null, autopct, null, false, startangle, null, null, null);
}

fn fill(x, y, color, alpha, label) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    return ax.fill(x, y, color, alpha, label);
}

fn fill_between(x, y1, y2, color, alpha, label) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    return ax.fill_between(x, y1, y2, null, false, "pre", color, alpha, label);
}

fn step(x, y, where, label) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    return ax.step(x, y, where, null, label, null, null, null);
}

fn stem(x, y, linefmt, markerfmt, label) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    return ax.stem(x, y, linefmt, markerfmt, null, 0, label, false);
}

fn errorbar(x, y, yerr, xerr, fmt, label) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    return ax.errorbar(x, y, yerr, xerr, fmt, null, null, null, null, label, null);
}

# ============================================================
# Specialized Plotting Functions
# ============================================================

fn heatmap(data, cmap, annot, fmt, linewidths, linecolor, cbar, vmin, vmax, center, robust, xticklabels, yticklabels, mask) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    
    let heatmap_data = {
        "type": "heatmap",
        "data": data,
        "cmap": cmap || "viridis",
        "annot": annot || false,
        "fmt": fmt || ".2f",
        "linewidths": linewidths || 0,
        "linecolor": linecolor || "white",
        "cbar": cbar !== false,
        "vmin": vmin || null,
        "vmax": vmax || null,
        "center": center || null,
        "robust": robust || false,
        "xticklabels": xticklabels || true,
        "yticklabels": yticklabels || true,
        "mask": mask || null
    };
    
    ax._collections.push(heatmap_data);
    ax._artists.push(heatmap_data);
    
    return [heatmap_data];
}

fn imshow(X, cmap, aspect, interpolation, vmin, vmax, origin, extent, shape, filternorm, filterrad, resample, url) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    
    let imshow_data = {
        "type": "imshow",
        "X": X,
        "cmap": cmap || "viridis",
        "aspect": aspect || "equal",
        "interpolation": interpolation || "nearest",
        "vmin": vmin || null,
        "vmax": vmax || null,
        "origin": origin || "upper",
        "extent": extent || null,
        "filternorm": filternorm !== false,
        "filterrad": filterrad || 4.0,
        "resample": resample !== false,
        "url": url || null
    };
    
    ax._collections.push(imshow_data);
    ax._artists.push(imshow_data);
    
    return [imshow_data];
}

fn pcolormesh(X, Y, C, cmap, vmin, vmax, shading, alpha) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    
    let pcolormesh_data = {
        "type": "pcolormesh",
        "X": X,
        "Y": Y,
        "C": C,
        "cmap": cmap || "viridis",
        "vmin": vmin || null,
        "vmax": vmax || null,
        "shading": shading || "flat",
        "alpha": alpha || 1.0
    };
    
    ax._collections.push(pcolormesh_data);
    ax._artists.push(pcolormesh_data);
    
    return [pcolormesh_data];
}

fn quiver(X, Y, U, V, C, length, scale, scale_units, angles, width, headwidth, headlength, headaxislength, color, alpha) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    
    let quiver_data = {
        "type": "quiver",
        "X": X,
        "Y": Y,
        "U": U,
        "V": V,
        "C": C,
        "length": length || 1,
        "scale": scale || null,
        "scale_units": scale_units || "width",
        "angles": angles || "uv",
        "width": width || null,
        "headwidth": headwidth || 3,
        "headlength": headlength || 5,
        "headaxislength": headaxislength || 4.5,
        "color": color || null,
        "alpha": alpha || 1.0
    };
    
    ax._collections.push(quiver_data);
    ax._artists.push(quiver_data);
    
    return [quiver_data];
}

fn streamplot(X, Y, U, V, density, linewidth, color, cmap, arrowsize, arrowstyle, integration_direction) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    
    let streamplot_data = {
        "type": "streamplot",
        "X": X,
        "Y": Y,
        "U": U,
        "V": V,
        "density": density || 1,
        "linewidth": linewidth || null,
        "color": color || null,
        "cmap": cmap || "viridis",
        "arrowsize": arrowsize || 1,
        "arrowstyle": arrowstyle || "->",
        "integration_direction": integration_direction || "both"
    };
    
    ax._collections.push(streamplot_data);
    ax._artists.push(streamplot_data);
    
    return [streamplot_data];
}

fn arrow(u, v, angles, scale, units, width, headwidth, headlength, headaxislength, color) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    
    let arrow_data = {
        "type": "arrow",
        "u": u,
        "v": v,
        "angles": angles || "xy",
        "scale": scale || 20,
        "units": units || "width",
        "width": width || 0.005,
        "headwidth": headwidth || 3,
        "headlength": headlength || 5,
        "headaxislength": headaxislength || 4.5,
        "color": color || "blue"
    };
    
    ax._artists.push(arrow_data);
    
    return [arrow_data];
}

fn barbs(X, Y, U, V, length, pivot, barbbin, barbudo, sizes, cmap, linewidth, color) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    
    let barbs_data = {
        "type": "barbs",
        "X": X,
        "Y": Y,
        "U": U,
        "V": V,
        "length": length || 7,
        "pivot": pivot || "tip",
        "barbbin": barbbin || 5,
        "barbudo": barbudo || 4.5,
        "sizes": sizes || {
            "spacing": 0.5,
            "height": 0.5,
            "width": 0.25
        },
        "cmap": cmap || "viridis",
        "linewidth": linewidth || 0.5,
        "color": color || "black"
    };
    
    ax._collections.push(barbs_data);
    ax._artists.push(barbs_data);
    
    return [barbs_data];
}

# ============================================================
# Statistical Plotting (Seaborn-like)
# ============================================================

fn distplot(a, bins, hist, kde, rug, fit, hist_kws, kde_kws, rug_kws, fit_kws, color, vertical, norm_hist) {
    let ax = gcf().add_axes([0.1, 0.1, 0.8, 0.8]);
    
    # Histogram
    if hist !== false {
        ax.hist(a, bins, null, norm_hist || false, false, null, "bar", "mid", "vertical", null, color || null, null, null, null);
    }
    
    # KDE (simplified)
    if kde {
        # Create KDE line
        let sorted_a = [...a];
        sorted_a.sort();
        let min_val = sorted_a[0];
        let max_val = sorted_a[len(sorted_a) - 1];
        let range_val = max_val - min_val;
        
        let x_kde = [];
        let y_kde = [];
        
        for let i in range(100) {
            let x = min_val + (i / 99) * range_val;
            x_kde.push(x);
            
            # Simple kernel density estimate
            let y = 0;
            for let xi in a {
                y = y + exp(-0.5 * pow((x - xi) / (0.1 * range_val), 2));
            }
            y_kde.push(y / len(a));
        }
        
        ax.plot(x_kde, y_kde, "-", null, null, 1.5, null, null, color || "blue", null);
    }
    
    # Rug plot
    if rug {
        for let val in a {
            ax.plot([val, val], [0, 0.02], "-", null, null, 0.5, null, null, "black", null);
        }
    }
    
    return ax;
}

fn jointplot(x, y, kind, stat_func, color, height, ratio, space, dropna, xlim, ylim) {
    kind = kind || "scatter";
    
    let fig = Figure.new([6, 6], 100, "white");
    
    # Main plot
    let ax_main = fig.add_axes([0.1, 0.1, 0.6, 0.6]);
    ax_main.scatter(x, y);
    
    # Marginal histograms
    let ax_hist_x = fig.add_axes([0.1, 0.75, 0.6, 0.15]);
    ax_hist_x.hist(x, 20);
    
    let ax_hist_y = fig.add_axes([0.75, 0.1, 0.15, 0.6]);
    ax_hist_y.hist(y, 20, orientation = "horizontal");
    
    return fig;
}

fn pairplot(data, hue, hue_order, vars, x_vars, y_vars, kind, diag_kind, markers, height, aspect, corner, dropna) {
    let n_vars = len(vars || data[0] || []);
    let n_rows = n_vars;
    let n_cols = n_vars;
    
    let fig = Figure.new([height * n_cols * aspect, height * n_rows], 100, "white");
    
    # Create grid of plots
    for let i in range(n_rows) {
        for let j in range(n_cols) {
            if i >= j {
                let ax = fig.add_axes([j * 0.1 + 0.05, (n_rows - i - 1) * 0.1 + 0.05, 0.08, 0.08]);
                
                if i == j {
                    # Diagonal - histogram
                    ax.hist(data[i],