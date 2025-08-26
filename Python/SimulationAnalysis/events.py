from dataclasses import dataclass, InitVar

@dataclass
class Event2d:
    x: int
    y: int
    p: int
    ts: int
    
    def __hash__(self):
        return hash((self.x, self.y, self.ts))
    
@dataclass
class EventExtTrigger:
    id: int
    p: int
    ts: int
    pad1: InitVar[int] = 0

    def __hash__(self):
        return hash((self.id, self.ts))

@dataclass(frozen=True, init=False)
class EventTypes:
    EVENT_2D: int = 0x00
    EVENT_CD: int = 0x0C
    EVENT_EXT_TRIGGER: int = 0x0E

@dataclass(frozen=True, init=False)
class EventFieldBytes:
    TOTAL = 8
    TIMESTAMP = 4
    ADDR = 4
