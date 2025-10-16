import { Type } from 'class-transformer';
import { IsNotEmpty, IsObject, ValidateNested } from 'class-validator';

class WindowDto {
  @IsNotEmpty()
  tz!: string;

  @IsNotEmpty()
  days!: number;
}

export class RescheduleInterviewDto {
  @IsObject()
  @ValidateNested()
  @Type(() => WindowDto)
  window!: WindowDto;
}
