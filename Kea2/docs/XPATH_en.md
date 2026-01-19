# Precondition Supported by Our XPath Extension

## Overview

Our XPath extension for uiautomator2 supports a variety of precondition formats to facilitate flexible and efficient element positioning. Below are the supported forms:

## Supported Formats

### Basic XPath Expression

You can use standard XPath expressions to locate elements.

```python
d.xpath('//*[@text="Private FM"]').exists
```

### Starting with @

You can use the `@` symbol followed by the resource ID to quickly locate elements.

```python
d.xpath('@personal-fm').exists # Equivalent to d.xpath('//*[@resource-id="personal-fm"]').exists
```

### Multiple Condition Positioning

You can chain multiple conditions to narrow down the element positioning, similar to using logical AND.

```python
d.xpath('//android.widget.Button').xpath('//*[@text="Private FM"]').exists
```

### Parent Element Positioning

You can locate the parent element of a matched element, with or without additional conditions.

```python
d.xpath('//*[@text="Private FM"]').parent_exists() # Position to the parent element
d.xpath('//*[@text="Private FM"]').parent_exists("@android:list") # Position to the parent element that meets the condition
```

### Child Element Positioning

You can locate child elements of a matched element. However, it is not recommended to use multiple condition XPath for child elements as it can be confusing.

```python
d.xpath('@android:id/list').child('/android.widget.TextView').exists
```

### Logical AND Queries

You can combine multiple XPath expressions using the `&` operator to perform logical AND queries.

```python
(d.xpath("NFC") & d.xpath("@android:id/item")).exists
```

### Logical OR Queries

You can combine multiple XPath expressions using the `|` operator to perform logical OR queries.

```python
(d.xpath("NFC") | d.xpath("App") | d.xpath("Content")).exists
```

### Complex Queries

You can create more complex queries by combining multiple conditions and expressions.

```python
((d.xpath("NFC") | d.xpath("@android:id/item")) & d.xpath("//android.widget.TextView")).exists
```

