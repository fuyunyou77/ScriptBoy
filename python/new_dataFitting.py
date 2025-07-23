import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import sympy as sp
# 读取Excel文件，指定行和列范围
# 锂电池拟合数据
# df = pd.read_excel("C:\\Users\\PC\\Documents\\Work_ZhaoChen\\UpperMachine\\锂电池容量与电压关系.xlsx", usecols="B:C", skiprows=0, nrows=16)  # 第一段拟合数据
# df = pd.read_excel("C:\\Users\\PC\\Documents\\Work_ZhaoChen\\UpperMachine\\锂电池容量与电压关系.xlsx", usecols="B:C", skiprows=15, nrows=3)  # 数据过度
# df = pd.read_excel("C:\\Users\\PC\\Documents\\Work_ZhaoChen\\UpperMachine\\锂电池容量与电压关系.xlsx", usecols="B:C", skiprows=17, nrows=5)  # 第二段拟合数据
# df = pd.read_excel("C:\\Users\\PC\\Documents\\Work_ZhaoChen\\UpperMachine\\锂电池容量与电压关系.xlsx", usecols="B:C", skiprows=21, nrows=3)  # 数据过度
df = pd.read_excel("C:\\Users\\PC\\Documents\\Work_ZhaoChen\\UpperMachine\\锂电池容量与电压关系.xlsx", usecols="B:C", skiprows=23, nrows=8)  # 第三段拟合数据

# 铅酸电池拟合数据
# df = pd.read_excel("C:\\Users\\PC\\Documents\\Work_ZhaoChen\\UpperMachine\\铅酸电池容量与电压关系.xlsx", usecols="A:B", skiprows=0, nrows=6)  # 第一段拟合数据
df = df.dropna()

# 提取数据
x = df.iloc[:, 0].values
y = df.iloc[:, 1].values

# 打印数据范围
print(f"X 范围: {min(x)} 到 {max(x)}")
print("x:")
print(x)
print(f"Y 范围: {min(y)} 到 {max(y)}")
print("y:")
print(y)

# 定义 R² 计算函数
def r2_score(y_true, y_pred):
    sst = np.sum((y_true - np.mean(y_true)) ** 2)
    sse = np.sum((y_true - y_pred) ** 2)
    r2 = 1 - (sse / sst)
    return r2

# 三次多项式拟合
degree = 3
coefficients = np.polyfit(x, y, deg=degree)
poly = np.poly1d(coefficients)

np.set_printoptions(precision=10)
print("高精度多项式系数：",coefficients)

# 使用 sympy 输出高精度公式
x_sym = sp.symbols('x')
poly_sym = sum(coeff * x_sym**(degree - i) for i, coeff in enumerate(coefficients))
print("高精度拟合公式:", sp.simplify(poly_sym))

y_poly=np.polyval(poly,11.27)
print("y_poly:")
print(y_poly)

y_pred = poly(x)
print("y_pred:")
print(y_pred)
r2 = r2_score(y, y_pred)

# 输出结果
print(f"拟合公式: y =\n {poly_sym}")
print(f"R²值: {r2:.4f}")

# 设置支持中文的字体
plt.rcParams['font.sans-serif'] = ['SimHei']  # 使用黑体
plt.rcParams['axes.unicode_minus'] = False  # 解决负号显示问题

# 绘图
plt.figure(figsize=(12, 10))
plt.scatter(x, y, color="blue", label="原始数据")
x_fit = np.linspace(min(x), max(x), 100)
plt.plot(x_fit, poly(x_fit), color="red", label="3次多项式拟合")
plt.xlabel("X", fontsize=12)
plt.ylabel("Y", fontsize=12)
plt.title("Figure 1", fontsize=14)
plt.legend(fontsize=12)
plt.grid(True)

# 在图像中添加拟合公式
formula = f"拟合公式: y = {poly_sym}"
plt.text(0.05, 0.95, formula, transform=plt.gca().transAxes, fontsize=12, verticalalignment='top', bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))

plt.show()