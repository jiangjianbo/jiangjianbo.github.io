---
layout: post
title: "CMS概念设计"
subtitle: "高度可配置的多平台内容呈现"
date: 2023-02-21
author: "BigTall"
header-img: "img/post-bg-sunset.jpg"
tags: 
    - CMS
    - DDD
    - 系统设计
---

## 前言

CMS已经是一个很老的概念了，但是在手机app、小程序、公众号大行其道的今天，CMS却感觉有些落伍。但是如果从它提供的价值角度看，现在正是应该大行其道的时间。业界开源的重量级CMS系统有很多，例如WordPress、Shopify、Joomla!、Drupal等，这些系统的架构对我影响还是蛮大的，尤其是Joomla，它的模板结构给人感觉很舒服。

我想要的CMS应该是什么样的？首先它需要管理各种类型的数据，并且在各种设备上进行可定制化的展示。比如支持PC网页、移动App、各种小程序等。同时，它也应该有能力接受业务模块的数据，并作为应用的展现前台，帮助业务模块对数据进行展现和收集反馈。

也就是说，我理想中的CMS应该包揽数据的展示和用户输入信息的采集，并为业务模块提供支持。这个流程类似网站的动静分离，只要是内容展现的活儿都留给CMS，开发者专心于业务逻辑的实现，甚至不需要考虑前端终端的种类和型号。

```plantuml
@startuml
left to right direction

actor user
component cms
component business
database "业务数据库"  as business_db
database "cms数据对象" as db

user -down-> cms : 访问请求/数据
cms .up.> user : 展示
cms -down-> business : 业务请求
business ..> cms : 业务数据
business -down-> business_db : 查询 
db -left-> cms : 数据对象

@enduml
```

从使用的角度，如果真的有了这种CMS的话，开发工作还可以简化，只需要关注核心对象和逻辑，界面视图的数据组合都不在需要考虑了。

## 概念模型

CMS系统的概念模型主要由两大块构成：数据部分和展现部分。

数据部分主要功能是把经过特征标注的数据提供给页面，以便页面可以把合适的内容呈现在特定的位置；展现部分则是把页面分解为布局、模板、组件，并提供最大限度的灵活性，通过配置组合就可以实现页面展示和交互。

### 数据

数据的抽象概念有两个层次，一个是数据，一个是视图。所谓的数据，其实就是数据实体，也可以理解为数据库或者任意的存储设备和格式的数据；所谓的视图，则是数据的多种组合方式。如果你理解 GraphQL 的话，可以理解得更透彻一些。

例如用户信息，当我们验证登录密码的时候，这个场景下的用户信息视图就只需要有用户名和密码即可；如果我们要显示用户的详细信息，那么视图包含的数据就更贴近用户实体的定义，要用户名、密码、昵称、备注、拥有的权限等；如果从用户特征分析的角度去看用户信息，除了用户名、昵称、备注之外，可能还要计算用户的各种标签。

### 展现概念模型

```plantuml

@startuml

package "数据" {
  class "目录" as dir
  class "数据对象" as dataobj
  class "数据属性" as dataprop
  class "对象属性" as propobj
  class "字段属性" as propfield
  class "内存数据" as memdata
  class "自定义数据" as udd
  class "外部数据" as odd
  class "数据源" as datasource
  class "数据库数据源" as db
  class "文件数据源" as file
  class "API接口数据源" as api
}

dir "1..*" --- dataobj
dataobj "0..*" --> "1" datasource
dataobj "1" *-left-> "0..*" dataprop : 属性
propobj --|> dataprop
propfield --|> dataprop

memdata -down-|> dataobj
udd -down-|> dataobj
odd -down-|> dataobj

db -up-|> datasource
file  -up-|> datasource
api  -up-|> datasource

package "展现" {
  class "页面定义" as pagedef
  class "页面数据" as pagedata
  class "页面模板" as tpl
  class "页面布局" as layout
  class "内容块" as block
  class "组件" as component
  class "空间" as space
  class "事件" as event
  class "状态机" as statemachine
  class "页面状态事件" as event_page
  class "页面跳转事件" as event_jump
  class "调用事件" as event_api
}

space "1" *--> "*" pagedef
pagedef "1" --> "*" pagedata : 数据
pagedef "1" -right-> "*" event
pagedef "1" --> "*" statemachine
pagedata "*" --> "*" dataobj : 数据
pagedef "*" --> "1" tpl : 模板
tpl "*" --> "1" layout : 布局
layout "*" --> "1" layout : 基础布局
layout "1" --> "1..*" block : 内容块
tpl "1" --> "*" block : 内容块
block "*" --> "*" component : 组件<<算法选择>>

event_page --|> event
event_jump --|> event
event_api --|> event



@enduml

```


## 