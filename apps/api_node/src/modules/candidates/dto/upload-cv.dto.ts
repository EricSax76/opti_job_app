import { IsNotEmpty, IsString } from 'class-validator';

export class UploadCvDto {
  @IsString()
  @IsNotEmpty()
  url!: string;
}
