"""
Pipeline: supply_chain_data.xlsx -> supply_chain.db (SQLite) -> Assignment_Script.sql
          -> results/*.csv + screenshots/*.png

Edit the Excel file (or regenerate it with generate_data.py), then run:
    python run_analysis.py
All tables, CSVs and charts are rebuilt from the new data.
"""
import os
import sqlite3

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd

XLSX = "supply_chain_data.xlsx"
DB = "supply_chain.db"
SQL = "Assignment_Script.sql"
os.makedirs("results", exist_ok=True)
os.makedirs("screenshots", exist_ok=True)

# ---------------------------------------------------------------- 1. Load Excel -> SQLite
if os.path.exists(DB):
    os.remove(DB)
con = sqlite3.connect(DB)
for sheet, df in pd.read_excel(XLSX, sheet_name=None).items():
    if sheet == "README":
        continue
    for col in df.columns:                      # store dates as ISO text (SQLite convention)
        if pd.api.types.is_datetime64_any_dtype(df[col]):
            df[col] = df[col].dt.strftime("%Y-%m-%d")
    df.to_sql(sheet, con, index=False)
    print(f"loaded {sheet:16s} {len(df):5d} rows")

# ---------------------------------------------------------------- 2. Run the SQL script
statements = [s.strip() for s in open(SQL, encoding="utf-8").read().split(";") if "SELECT" in s.upper()]
names = ["revenue", "pareto_abc", "abc_summary", "component_movement"]
res = {n: pd.read_sql_query(s, con) for n, s in zip(names, statements)}
for n, df in res.items():
    df.to_csv(f"results/{n}.csv", index=False)
con.close()

rev, pareto, abc, comp = (res[n] for n in names)

# ---------------------------------------------------------------- 3. Charts
INK, INK2, GRID, SURF = "#0b0b0b", "#52514e", "#e4e3df", "#fcfcfb"
BLUE, ORANGE, AQUA, GRAY = "#2a78d6", "#eb6834", "#1baf7a", "#a9a8a2"
ABC_COLOR = {"A": BLUE, "B": ORANGE, "C": AQUA}

plt.rcParams.update({
    "font.family": "DejaVu Sans", "font.size": 10, "text.color": INK,
    "axes.edgecolor": GRID, "axes.labelcolor": INK2, "axes.facecolor": SURF,
    "figure.facecolor": SURF, "xtick.color": INK2, "ytick.color": INK2,
    "axes.spines.top": False, "axes.spines.right": False,
    "axes.titleweight": "bold", "axes.titlesize": 12, "axes.titlelocation": "left",
})


def money(v):
    return f"€{v/1e6:.2f}M" if v >= 1e6 else f"€{v/1e3:.0f}k"


# 3a. Top products by revenue, coloured by ABC class
top = pareto.head(15).iloc[::-1]
fig, ax = plt.subplots(figsize=(9, 6))
ax.barh(top["product_id"], top["total_revenue"], height=0.7,
        color=[ABC_COLOR[c] for c in top["abc_class"]], edgecolor=SURF, linewidth=2)
for y, (v, p) in enumerate(zip(top["total_revenue"], top["revenue_pct"])):
    ax.text(v, y, f"  {money(v)} · {p:.1f}%", va="center", fontsize=9, color=INK2)
ax.set_xlim(0, top["total_revenue"].max() * 1.3)
ax.xaxis.set_major_formatter(lambda x, _: money(x) if x else "0")
ax.grid(axis="x", color=GRID, linewidth=0.8)
ax.set_axisbelow(True)
ax.set_title("Top 15 products by revenue")
ax.legend(handles=[plt.Rectangle((0, 0), 1, 1, color=ABC_COLOR[k]) for k in "ABC"
                   if k in set(top["abc_class"])],
          labels=[f"Class {k}" for k in "ABC" if k in set(top["abc_class"])],
          frameon=False, loc="lower right")
fig.tight_layout()
fig.savefig("screenshots/revenue_analysis.png", dpi=150)
plt.close(fig)

# 3b. Pareto curve: cumulative % of revenue vs % of products
n = len(pareto)
x = [0] + [100 * (i + 1) / n for i in range(n)]
y = [0] + pareto["cumulative_pct"].tolist()
fig, ax = plt.subplots(figsize=(9, 5.5))
start = 0
for cls in "ABC":
    cnt = (pareto["abc_class"] == cls).sum()
    if cnt:
        ax.axvspan(100 * start / n, 100 * (start + cnt) / n, color=ABC_COLOR[cls], alpha=0.10, lw=0)
        ax.text(100 * (start + cnt / 2) / n, 4, f"{cls}\n{cnt} products", ha="center",
                fontsize=9, color=INK2, fontweight="bold")
        start += cnt
ax.plot(x, y, color=BLUE, linewidth=2, marker="o", markersize=4, markeredgecolor=SURF)
for t in (80, 95):
    ax.axhline(t, color=INK2, linestyle=(0, (4, 3)), linewidth=0.8)
    ax.text(101, t, f"{t}%", va="center", fontsize=9, color=INK2)
ax.set_xlim(0, 100)
ax.set_ylim(0, 102)
ax.set_xlabel("% of products (ranked by revenue)")
ax.set_ylabel("Cumulative % of revenue")
ax.grid(color=GRID, linewidth=0.8)
ax.set_axisbelow(True)
ax.set_title("Pareto curve with ABC classes")
fig.tight_layout()
fig.savefig("screenshots/pareto_analysis.png", dpi=150)
plt.close(fig)

# 3c. Component movement: count per status and value of stock tied up
STATUS_ORDER = ["Slow-moving (excess risk)", "Normal", "Fast-moving (stockout risk)",
                "Shortage / missing opening stock", "Demand without receipts (check data)", "No activity"]
STATUS_COLOR = {STATUS_ORDER[0]: ORANGE, STATUS_ORDER[1]: GRAY, STATUS_ORDER[2]: BLUE,
                STATUS_ORDER[3]: "#e34948", STATUS_ORDER[4]: "#c9c8c2", STATUS_ORDER[5]: "#c9c8c2"}
summary = (comp.groupby("movement_status")
           .agg(components=("component_id", "count"),
                stock_value=("net_stock_value", lambda s: s.clip(lower=0).sum()))
           .reindex([s for s in STATUS_ORDER if s in set(comp["movement_status"])]))
summary.to_csv("results/component_status_summary.csv")

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11, 4.8), sharey=True)
labels = summary.index[::-1]
cols = [STATUS_COLOR[s] for s in labels]
ax1.barh(labels, summary["components"][::-1], color=cols, height=0.7, edgecolor=SURF, linewidth=2)
for i, v in enumerate(summary["components"][::-1]):
    ax1.text(v, i, f"  {v}", va="center", fontsize=9, color=INK2)
ax1.set_title("Components by movement status")
ax1.set_xlim(0, summary["components"].max() * 1.25)
ax2.barh(labels, summary["stock_value"][::-1], color=cols, height=0.7, edgecolor=SURF, linewidth=2)
tot = summary["stock_value"].sum()
for i, v in enumerate(summary["stock_value"][::-1]):
    ax2.text(v, i, f"  {money(v)} ({100*v/tot:.0f}%)" if v else "  –", va="center", fontsize=9, color=INK2)
ax2.set_title("Net stock value left over")
ax2.set_xlim(0, summary["stock_value"].max() * 1.45)
ax2.xaxis.set_major_formatter(lambda x, _: money(x) if x else "0")
for a in (ax1, ax2):
    a.grid(axis="x", color=GRID, linewidth=0.8)
    a.set_axisbelow(True)
fig.tight_layout()
fig.savefig("screenshots/inventory_turnover.png", dpi=150)
plt.close(fig)

# ---------------------------------------------------------------- 4. Console summary
print("\nABC summary\n", abc.to_string(index=False))
print("\nComponent status\n", summary.to_string())
print("\nTotal revenue:", round(pareto['total_revenue'].sum(), 2))
