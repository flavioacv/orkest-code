# Python sample fixture
from dataclasses import dataclass

@dataclass
class Item:
    name: str
    price: float

def calculate_total(items: list[Item]) -> float:
    return sum(item.price for item in items)
