from enum import Enum
from pydantic import BaseModel, Field

class ImageFormat(str, Enum):
  QCOW2 = "qcow2"
  RAW = "raw"

class ImageUnit(str, Enum):
  GB = "GB"
  MB = "MB"

class CreateVMImageRequest(BaseModel):
  name: str = Field(min_length=1, max_length=100)
  smp: int = Field(gt=0)
  unit: ImageUnit = ImageUnit.GB
  disksize: int = Field(gt=0)
  ramsize: int = Field(gt=0)
  isoimage: str = Field(min_length=1)
  format: ImageFormat = ImageFormat.QCOW2
  vncsupport: str = ":0,password=on"
  monitor: str = "stdio"