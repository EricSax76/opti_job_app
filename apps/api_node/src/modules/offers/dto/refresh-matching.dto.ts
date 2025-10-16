import { IsNumber, IsOptional } from 'class-validator';

export class RefreshMatchingDto {
  @IsNumber()
  @IsOptional()
  top?: number;
}
