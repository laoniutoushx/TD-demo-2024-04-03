# thermal_analysis.py
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import plotly.express as px

# ========== 模拟数据生成 ==========
def generate_sample_data():
    # 空间坐标热力图数据
    np.random.seed(42)
    spatial_data = pd.DataFrame({
        'X': np.random.uniform(0, 5, 20),      # 机舱X坐标（0-5米）
        'Y': np.random.uniform(0, 4, 20),      # 机舱Y坐标（0-4米）
        'Temp': np.random.normal(45, 5, 20)    # 温度值（均值45℃）
    })
    
    # 部件关联数据
    time_index = pd.date_range('2023-01-01', periods=100, freq='H')
    component_data = pd.DataFrame({
        '时间': time_index,
        '机舱温度': np.random.normal(40, 3, 100),
        '齿轮箱温度': np.random.normal(55, 5, 100),
        '发电机温度': np.random.normal(48, 4, 100),
        '变流器温度': np.random.normal(60, 6, 100)
    })
    return spatial_data, component_data

# ========== 可视化函数 ==========
def plot_spatial_heatmap(data):
    """ 空间分布热力图 """
    fig = px.density_heatmap(
        data, x='X', y='Y', z='Temp',
        nbinsx=20, nbinsy=20,
        color_continuous_scale='jet',
        labels={'color': '温度(℃)'},
        title="机舱空间温度分布热力图"
    )
    fig.update_layout(width=800, height=600)
    fig.show()

def plot_correlation_heatmap(data):
    """ 部件温度相关性热力图 """
    corr_matrix = data.corr()
    
    plt.figure(figsize=(10, 8))
    sns.heatmap(
        corr_matrix, 
        annot=True, 
        cmap='coolwarm', 
        vmin=-1, vmax=1,
        mask=np.triu(np.ones_like(corr_matrix))  # 隐藏上半三角
    )
    plt.title("部件温度相关性分析")
    plt.xticks(rotation=45, ha='right')
    plt.tight_layout()
    plt.show()


# ========== 主程序 ==========
if __name__ == "__main__":
    # 生成模拟数据
    spatial_df, component_df = generate_sample_data()
    
    # 绘制空间热力图（交互式）
    plot_spatial_heatmap(spatial_df)
    
    # 绘制关联热力图（静态）
    plot_correlation_heatmap(component_df.drop(columns='时间'))