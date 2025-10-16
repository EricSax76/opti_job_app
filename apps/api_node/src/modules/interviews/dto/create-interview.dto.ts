import { IsNotEmpty, IsObject, IsString, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

class WindowDto {
  @IsNotEmpty()
  @IsString()
  tz!: string;

  @IsNotEmpty()
  days!: number;
}

export class CreateInterviewDto {
  @IsString()
  @IsNotEmpty()
  offerId!: string;

  @IsString()
  @IsNotEmpty()
  candidateId!: string;

  @IsObject()
  @ValidateNested()
  @Type(() => WindowDto)
  window!: WindowDto;
}
