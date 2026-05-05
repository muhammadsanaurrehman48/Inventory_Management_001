import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
import os

# 1. Locate the exported file
file_path = 'data/export.csv'

if not os.path.exists(file_path):
    print(f"[!] Error: '{file_path}' not found. Run your Assembly IMS and export first!")
    exit()

# 2. Load the data
df = pd.read_csv(file_path)
df.columns = df.columns.str.strip()

# 3. Calculate Real Business Metrics
df['Total Value (Rs)'] = df['Quantity'] * df['Price']
df['Revenue (Rs)'] = df['Units Sold'] * df['Price']

# 4. Setup Native Desktop Window & Dark Theme
plt.style.use('dark_background')
# Made the figure slightly taller (10) to accommodate the extra spacing
fig = plt.figure(figsize=(20, 10)) 
fig.canvas.manager.set_window_title('IMS Executive Analytics')

# Setup Grid Layout: 2 rows, 4 columns
# Increased hspace to 0.5 to give the table more room below the graphs
gs = GridSpec(2, 4, height_ratios=[1.3, 1], hspace=0.5, wspace=0.3) 

ax1 = plt.subplot(gs[0, 0]) 
ax2 = plt.subplot(gs[0, 1]) 
ax3 = plt.subplot(gs[0, 2]) 
ax4 = plt.subplot(gs[0, 3]) 
ax5 = plt.subplot(gs[1, :]) 

# Pushed the main title higher up by setting y=0.98
fig.suptitle('IMS Executive Analytics Dashboard', fontsize=26, fontweight='bold', color='cyan', y=0.98)

# --- Chart 1: Stock Levels ---
bars1 = ax1.bar(df['Item Name'], df['Quantity'], color='#00E676')
# Added pad=20 to push the title away from the graph
ax1.set_title('Current Stock Levels', fontsize=14, color='white', pad=20)
ax1.set_ylabel('Units in Stock')
ax1.tick_params(axis='x', rotation=25)
ax1.spines['top'].set_visible(False)
ax1.spines['right'].set_visible(False)

for bar in bars1:
    yval = bar.get_height()
    ax1.text(bar.get_x() + bar.get_width()/2, yval + (yval*0.02), int(yval), ha='center', va='bottom', color='white', fontweight='bold', fontsize=10)

# --- Chart 2: Total Asset Value ---
bars2 = ax2.bar(df['Item Name'], df['Total Value (Rs)'], color='#00B0FF')
ax2.set_title('Unsold Asset Value (Rs)', fontsize=14, color='white', pad=20)
ax2.set_ylabel('Value in Rupees')
ax2.tick_params(axis='x', rotation=25)
ax2.spines['top'].set_visible(False)
ax2.spines['right'].set_visible(False)

for bar in bars2:
    yval = bar.get_height()
    ax2.text(bar.get_x() + bar.get_width()/2, yval + (yval*0.02), f"{int(yval):,}", ha='center', va='bottom', color='white', fontweight='bold', fontsize=10)

# --- Chart 3: Sales Record ---
ax3.plot(df['Item Name'], df['Units Sold'], color='#FF3D00', marker='o', linewidth=3, markersize=8)
ax3.fill_between(df['Item Name'], df['Units Sold'], color='#FF3D00', alpha=0.2)
ax3.set_title('Sales Volume (Units Sold)', fontsize=14, color='white', pad=20)
ax3.set_ylabel('Units Sold')
ax3.tick_params(axis='x', rotation=25)
ax3.spines['top'].set_visible(False)
ax3.spines['right'].set_visible(False)

max_y = df['Units Sold'].max() if not df['Units Sold'].empty else 10
offset = max_y * 0.05 if max_y > 0 else 1
for i, txt in enumerate(df['Units Sold']):
    ax3.annotate(txt, (df['Item Name'][i], df['Units Sold'][i] + offset), ha='center', color='white', fontweight='bold', fontsize=10)

# --- Chart 4: Realized Revenue ---
bars4 = ax4.bar(df['Item Name'], df['Revenue (Rs)'], color='#B388FF') 
ax4.set_title('Realized Revenue (Rs)', fontsize=14, color='white', pad=20)
ax4.set_ylabel('Revenue in Rupees')
ax4.tick_params(axis='x', rotation=25)
ax4.spines['top'].set_visible(False)
ax4.spines['right'].set_visible(False)

for bar in bars4:
    yval = bar.get_height()
    ax4.text(bar.get_x() + bar.get_width()/2, yval + (yval*0.02), f"{int(yval):,}", ha='center', va='bottom', color='white', fontweight='bold', fontsize=10)

# --- The Data Table ---
ax5.axis('off') 
table_data = df.values.tolist()
columns = df.columns.tolist()

table = ax5.table(cellText=table_data, colLabels=columns, loc='center', cellLoc='left')
table.auto_set_font_size(False)
table.set_fontsize(12)
table.scale(1, 2) 

for (row, col), cell in table.get_celld().items():
    if row == 0:
        cell.set_text_props(weight='bold', color='cyan')
        cell.set_facecolor('#1A1A1A')
    else:
        cell.set_facecolor('#2D2D2D')
    cell.set_edgecolor('#404040')

# Dropped the top boundary from 0.94 to 0.88 to give the main title a massive buffer
plt.tight_layout(rect=[0, 0, 1, 0.88])
plt.show()