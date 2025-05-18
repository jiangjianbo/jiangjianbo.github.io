---
layout: post
title: "AI模型的回调能力的理解和实现"
subtitle: "AI"
date: 2025-05-17
author: "BigTall"
header-img: "img/post-bg-sunset.jpg"
tags: 
    - 大模型
    - AI
    - 原理
---

## 前言

我BigTall最近把`RAG`和`Agent`的原理想通了，对于“一切都是提示词”的理解又更多了一些。本文把我的理解大致整理了一下，给出BigTall自己的一个实验。希望能够对大家有用。


## 关于大模型

现在大模型很热，尤其是春节时候`DeepSeek`的出圈，直接让大模型跳出了`IT`圈，跟普通人产生了联系。最近的豆包相关的“我要去世了”文章，让大模型加上了一层人性与情感的光环。北京的机器人马拉松则让人看到了大模型真正落地进入人们生活的一个可能，让更多的人明白了“未来已来，只是尚未流行”。

我们每一分每一秒，都在踏步进入科幻时代。

但是大模型依然神秘。

大模型的出现提供了什么以前缺乏的能力？我思考的答案是：真正处理“模糊”的能力！以往用代码编写出来的“模糊”都是用基于精确匹配的改良：要么用偏移量多匹配几次，要么转化为数学相似度做一个范围取值。但是真正能够基于“语义”上的模糊匹配能力，而且可以直接使用的，大模型是唯一。

对于传统软件开发者来说，大模型更多是一种`DSL`（`Domain Specific Language`）领域驱动语言，是一种“功能的粘合剂”。本质上跟你嵌入一个`JavaScript`引擎没多大区别，只不过大模型可以支持自然语言和模糊处理而已，但对于程序来说，都是提供功能调用入口，让`DSL`进行调用而已。

作为一个语言模型，文字是大模型唯一的输入和输出形式。我们是怎么做到让大模型去控制外部的设备的？我们是怎么做到大模型可以自主在网络上搜寻信息并向我们展示的？它又是如何读懂我给他的文档，帮我进行内容解释的？

提示词就是一切！

有了提示词的魔法，我们可以简单一句“请帮我规划到丽江的旅游”，驱动大模型帮我们去分解任务，寻找景点、规划线路、寻找住宿、寻找合适的交通工具、询价甚至直接订票。

魔法一样的技术背后，是多轮的提示词往来。

### RAG应用

RAG应用的基本原理是把文档放向量数据库里，用户询问的问题会也向量化，跟向量数据库的内容做相似度查找，找到的前10条结果会组合成提示词以文字形式送给背后的AI渲染。背后的提示词类似：【问题xxx找到abcd等几个相似文档，文档该要和匹配片段分别是xyz，请分析并给出答案】。

### 智能体

`Agent`就是智能体，所谓的智能体就是一段特定任务相关的提示词，智能体背后可以是同一个`AI`，也可以是不同的`AI`。你可以认为智能体就是对应一组提示词的化身，通过把某个能力相关（例如订票）的一组提示词放在一个“智能体”中，实现任务的专有性。也符合软件开发领域【高内聚低耦合】的原理。

多个智能体之间的合作，就等价于多个提示词之间的合作，有任务分解的、有对结果监督的、有驱动过程的不同的提示词对应的`Agent`。

例如【我要去桂林旅行】，就可以分解为几个智能体：

1. 将文字整理成任务片段的：理解文字内容，并将文字分解成步骤和动作，负责总控和协调其他专有`Agent`的执行。
2. 查机票火车票的：通过`RAG`的方式，大模型生成参数，调用外部的查询接口查到各种交通工具的信息，提供其他`Agent`使用。
3. 整理行程的：负责从知识库或者网络查询检索获得一组行程，并根据用户的需求挑选出最合适的行程。
4. 查桂林景点的：负责从知识库或者网络查询获得桂林的景点，并根据用户需求挑选出最合适的景点。
5. 整理旅游计划的：将以上的信息综合，组合成旅游计划。

这个只是简单的说明，实际上智能体之间的关系是一个网状关系，非常复杂。所以智能体组合的运行速度其实很慢。

### 大模型回调

所谓的大模型和本地程序的回调，等价于提示词：【我现在有什么任务，这些是可以调用的本地接口定义如下123，请回复问题位置中插入适当的本地接口调用】。然后，你问ai，今天早上我要穿什么衣服？然后`AI`就会返回一个带占位符的文字【今天温度是`${weather(2025-5-17)}`，请告诉我要穿什么衣服】，你的程序会把${}中的函数计算并嵌入结果，结果`AI`收到【今天温度25度，请告诉我要穿什么衣服】，然后ai再返回结果【穿短袖】。

大致原理就是这样，只不过支持回调的大模型都经过专门训练，可以使用`json`结构来定义回调函数，并且他们的回调准确率也更高。

### MCP和A2A协议

说到这里，大家应该明白了，大模型离不开和外部的协作。所以需要一个大模型控制外部设施的协议。另外，刚才讲智能体协作的时候，很明显智能体之间存在通讯关系，因此也需要一个通讯协议。

`MCP`（`Model Context Protocol`）模型上下文协议由`Anthropic`（`Claude` 模型的开发公司）提出，`OpenAI`后续跟随采用让它成为事实上的标准。该协议就是让大模型和外部协作的。有人可能会说，大模型那么智能，我们让大模型学会各个系统的交互，就可以不要什么`MCP`了。有道理，但是大模型要记住这些的话，需要记忆，花这么多代价去训练怎么跟外部交互是不是很浪费？！未来还会有更多的新系统出现，难道不间断去训练吗？所以合理的方式就是让每个想和大模型协作的外部程序都学会“普通话”，能够和大模型对话，接受大模型的指令。

`A2A`（`Agent to Agent`）由`Google`主导开发，定位为跨平台、跨厂商的`AI` 智能体之间的通讯协议。等于让智能体都加入了一个群，智能体们可以在群里互相`@`进行交流。大家看刚才旅游订票的例子就可以看到，智能体之间的交互其实并不比智能体和大模型之间的交互要来的少多少。


## `QWen3 0.6B`的回调实验

无论是`MCP`还是`A2A`，还是普通的大模型功能调用，本质都是一回事：提示词输入通过大模型变成答案输出，答案又变成下一次的输入。来来回回，就把事情办完了。

这次我们的实验，就是把不支持回调的本地小模型改造成可以支持回调。让小模型也可以和代码进行交互。

### 实验环境

实验环境首先需要安装`Ollama`，一个决心要像使用`docker`一样使用大模型的环境。大家去官网 https://ollama.com/ 下载安装，并且启动运行（确保任务栏里有白色羊驼的图标）。

```bash
ollama pull qwen3:0.6b
```
另外，需要安装`python3`。我机器是`MacBook Pro`，所以用`brew`安装，其他操作系统请自己安装环境。

```bash
brew install python
mkdir ~/qwen3-callback
cd ~/qwen3-callback
python3 -m venv .
source ./bin/activate
python3 -m pip install requests
```
### 代码

把以下的源代码放到文件`callback.py`中。

```python
import requests
import re
import json

# Ollama API 配置
OLLAMA_API_URL = "http://localhost:11434/api/generate"
MODEL_NAME = "qwen3:0.6b"

# 模拟的天气函数
def weather(date):
    # 实际场景可调用天气 API，这里模拟返回 25 度
    return 35

def find_goods(item):
    # 模拟返回商品信息
    return f"""
List {item} brand: 
- Apple: MacBook Pro, MacBook Air
- Dell: XPS, Inspiron
- HP: Spectre, Envy
- Lenovo: ThinkPad, IdeaPad
- Microsoft: Surface
- Razer: Blade
- Samsung: Galaxy Book
- Sony: VAIO
"""

def find_goods_prices(item):
    # 模拟返回商品价格
    return f"{item} 5999.00元"


# 调用 Ollama API 的函数
def call_ollama(prompt, model=MODEL_NAME):
    payload = {
        "model": model,
        "prompt": prompt,
        "stream": False,
        "temperature": 1 
    }
    response = requests.post(OLLAMA_API_URL, json=payload)
    if response.status_code == 200:
        return json.loads(response.text)["response"]
    else:
        raise Exception(f"Ollama API error: {response.text}")

# 提取 </think> 之后的文本
def extract_post_think_text(text):
    markers = ["</think>", "提示词", "提示词**", "输出：", "输出:"]
    last_pos = -1
    last_marker = None
    
    # Find the last occurrence of any marker
    for marker in markers:
        try:
            pos = text.rindex(marker)  # Get the last index of the marker
            if pos > last_pos:
                last_pos = pos
                last_marker = marker
        except ValueError:
            continue  # Marker not found, skip
    
    # If a marker was found, return text after it
    if last_pos != -1:
        return text[last_pos + len(last_marker):].strip()
    
    # If no markers found, return original text
    return text.strip()


# 解析占位符并执行函数调用
def process_placeholder(text):
    # 查找 ${function(args)} 模式的占位符
    placeholder_pattern = r'\${([^}]+)\}'
    matches = re.findall(placeholder_pattern, text)
    
    if not matches:
        return text  # 没有占位符，直接返回原文
    
    for match in matches:
        # 处理函数调用格式：${function(arg)}
        if '(' in match and ')' in match:
            func_name = match.split('(')[0].strip()
            func_arg = match.split('(')[1].rstrip(')').strip()

            if func_name == "weather":
                result = weather(func_arg)
                text = text.replace(f"${{{match}}}", f"{result}")
            elif func_name == "find_goods":
                result = find_goods(func_arg)
                text = text.replace(f"${{{match}}}", f"{result}")
            elif func_name == "find_goods_prices":
                result = find_goods_prices(func_arg)
                text = text.replace(f"${{{match}}}", f"${result}")
            else:
                text = text.replace(f"${{{match}}}", "[Unknown function]")
        else:
            text = text.replace(f"${{{match}}}", "[Invalid placeholder]")
    
    return text

# 主逻辑
def main():
    # 用户输入
    # user_input = "今天我要穿什么衣服？"
    # user_input = "请给我推荐一台性价比高的电脑"
    # user_input = "我想买一个苹果笔记本电脑，需要准备多少预算？"
    user_input = "列出中国历朝历代的名称"
    print(f"用户输入: {user_input}")
    print("======================")
    
    # 第一次调用模型，生成带占位符的提示词
    initial_prompt = f"""
今天是2025年5月17日。
用户问题：{user_input}
可用函数：
- weather('2025-5-17'): 返回当天的摄氏温度。
- find_goods(item): 返回商品信息（item可以是商品类别、产品名、型号等，如“mobile”或“Samsung”货“Galaxy S”，基于用户问题的主关键词）。
- find_goods_prices(item): 返回指定商品的价格（item同上）
推理：回答需要什么信息？选择一个函数。若问题未指定具体item，从问题中提取主关键词（如“电脑”）作为item。
     生成提示词，仅输出：${{function(arg)}}提供的信息，请回答：{{用户问题}}。禁止附加任何说明或逻辑。
例如：
- 输入：“今天热不热？”，输出：“${{weather('2025-5-17')}}提供的信息，请回答：今天热不热？”
- 输入：“推荐一台笔记本电脑？”，输出：“${{find_goods('laptop')}}提供的信息，请回答：推荐一台笔记本电脑？”
- 输入：“衬衫多少钱？”，输出：“${{find_goods_prices('shirt')}}提供的信息，请回答：衬衫多少钱？
- 输入：“爱因斯坦的生平”，输出：“请回答：爱因斯坦的生平
    """
    print(f"初始提示词: {initial_prompt}")
    
    response = call_ollama(initial_prompt)
    print("======================")
    print(f"模型第一次响应: {response}")
        
    # 提取 </think> 之后的文本
    post_think_text = extract_post_think_text(response)
    print("======================")
    print(f"</think> 后的文本: {post_think_text}")
    
    # 处理占位符，调用外部函数
    processed_response = process_placeholder(post_think_text)
    print("======================")
    print(f"处理占位符后的文本: {processed_response}")
    
    # 第二次调用模型，使用回填后的提示词
    final_prompt = f"""
    根据以下信息回答用户的问题：
    {processed_response}
    """
    print("======================")
    print(f"最终提示词: {final_prompt}")
    
    final_response = call_ollama(final_prompt)
    print("======================")
    print(f"最终回答: {final_response}")

if __name__ == "__main__":
    main()
```
### 运行结果

整个程序运行完成之后是这样的输出内容：

```text
$ python3 ./callback.py
用户输入: 今天天气适合穿什么衣服？
======================
初始提示词:
今天是2025年5月17日。
用户问题：今天天气适合穿什么衣服？
可用函数：
- weather('2025-5-17'): 返回当天的摄氏温度。
- find_goods(item): 返回商品信息（item可以是商品类别、产品名、型号等，如“mobile”或“Samsung”货“Galaxy S”，基于用户问题的主关键词）。
- find_goods_prices(item): 返回指定商品的价格（item同上）
推理：回答需要什么信息？选择一个函数。若问题未指定具体item，从问题中提取主关键词（如“电脑”）作为item。
     生成提示词，仅输出：${function(arg)}提供的信息，请回答：{用户问题}。禁止附加任何说明或逻辑。
例如：
- 输入：“今天热不热？”，输出：“${weather('2025-5-17')}提供的信息，请回答：今天热不热？”
- 输入：“推荐一台笔记本电脑？”，输出：“${find_goods('laptop')}提供的信息，请回答：推荐一台笔记本电脑？”
- 输入：“衬衫多少钱？”，输出：“${find_goods_prices('shirt')}提供的信息，请回答：衬衫多少钱？
- 输入：“爱因斯坦的生平”，输出：“请回答：爱因斯坦的生平

======================
模型第一次响应: <think>
好的，用户的问题是今天天气适合穿什么衣服，需要回答。首先，我需要确定可用的函数。用户的问题中提到了天气，所以应该使用weather函数来获取温度信息。然后，根据问题中的主关键词“天气”，可能需要提取这个关键词作为item，但问题中并没有具体商品类别，所以可能直接使用天气数据。接下来，生成提示词，只输出函数调用的结果，不需要其他说明。例如，用户的问题中没有指定商品，所以主关键词是“天气”，所以调用weather函数，然后给出回答。确保不添加任何其他说明，只输出指定的格式。
</think>

${weather('2025-5-17')}提供的信息，请回答：今天天气适合穿什么衣服？
======================
</think> 后的文本: ${weather('2025-5-17')}提供的信息，请回答：今天天气适合穿什么衣服？
======================
处理占位符后的文本: '2025-5-17' 的天气是 35°C提供的信息，请回答：今天天气适合穿什么衣服？
======================
最终提示词:
    根据以下信息回答用户的问题：
    '2025-5-17' 的天气是 35°C提供的信息，请回答：今天天气适合穿什么衣服？

======================
最终回答: <think>
好的，用户的问题是根据“2025-5-17”当天的天气35°C，回答今天适合穿什么衣服。首先，我需要确认用户提供的天气信息是否正确，然后根据温度来判断合适的服装。

首先，用户给出的信息是35°C，这通常意味着白天的温度在35度左右，可能还有傍晚的温度稍低。不过，具体天气情况可能还需要参考其他数据，比如是否有风、湿度等。但用户只提供了温度，所以需要假设白天是35度，可能在下午或晚上有降温。

接下来，考虑适合穿什么衣服。通常，白天的温度较高，所以可能会穿短袖、T恤、短裤和长袖衬衫。同时，考虑到天气可能比较热，建议选择透气、吸汗的面料，比如棉质或透气面料。另外，可能还需要考虑防晒，所以帽子和太阳镜也很重要。

不过，用户的问题可能只需要根据给出的信息直接回答，不需要考虑其他因素。所以综合来看，最合适的回答应该是推荐短袖、T恤、短裤和长袖衬衫，同时考虑防晒措施。

需要检查是否有其他可能的因素，比如是否有雨天，但用户只提到了温度，所以可能不需要考虑其他天气情况。因此，最终回答应基于温度和常见天气模式，给出具体的穿衣建议。
</think>

根据今天的天气情况，35°C的高温天气适合穿短袖、T恤、短裤和长袖衬衫。建议搭配防晒用品（如帽子和太阳镜）以保持舒适和安全。
```
## 总结

不知道有多少人会看到这里。

操控`AI`模型其实没什么难度，最大的难度还是在“提示词的调试”，你需要不停的试错，不停地和模型的理解能力和幻觉做斗争。模型参数量越小，这个调试的难度就越大，因为小模型本来就很笨。

这次调试多亏了`Grok`，否则要拿捏住`0.6B`的小模型不被它蠢哭，还真不容易。至于Big Tall是怎么跟`Grok`对话最终降伏小模型的?

不告诉你！

提示词才是`AI`时代最大的秘密！
