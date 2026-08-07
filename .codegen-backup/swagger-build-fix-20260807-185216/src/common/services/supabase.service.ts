import {
  Injectable,
  InternalServerErrorException,
  BadRequestException,
} from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { ConfigService } from '@nestjs/config';
import { SafeLogger } from 'src/common/utils/logger.util';

@Injectable()
export class SupabaseService {
  private supabase: SupabaseClient;
  private bucketName: string;

  constructor(private configService: ConfigService) {
    this.supabase = createClient(
      this.configService.get<string>('SUPABASE_URL'),
      this.configService.get<string>('SUPABASE_SERVICE_ROLE_KEY') ||
        this.configService.get<string>('SUPABASE_ANON_KEY'),
    );
    this.bucketName = this.configService.get<string>('SUPABASE_BUCKET_NAME');
  }

  async uploadImage(
    file: Express.Multer.File,
    folderName: string,
  ): Promise<string> {
    try {
      // Test connection first
      await this.testConnection();

      // Validate file exists
      if (!file) {
        throw new BadRequestException('No file provided');
      }

      // Validate file size (2MB = 2 * 1024 * 1024 bytes)
      const maxSize = 2 * 1024 * 1024; // 2MB in bytes

      if (file.size > maxSize) {
        throw new BadRequestException('Image size must be 2MB or less');
      }

      // Validate file type
      const allowedMimeTypes = [
        'image/jpeg',
        'image/png',
        'image/webp',
        'image/gif',
      ];
      if (!allowedMimeTypes.includes(file.mimetype)) {
        throw new BadRequestException(
          'Only JPEG, PNG, WebP, and GIF images are allowed',
        );
      }

      // Generate unique filename
      const fileExtension = file.originalname.split('.').pop();
      const fileName = `${folderName}/${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExtension}`;

      // Upload the file to the bucket
      const { error } = await this.supabase.storage
        .from(this.bucketName)
        .upload(fileName, file.buffer, {
          cacheControl: '3600',
          upsert: false,
          contentType: file.mimetype,
        });

      if (error) {
        SafeLogger.error(
          `Supabase upload error details: ${JSON.stringify(error)}`,
          'SupabaseService',
        );
        SafeLogger.error(
          `Bucket: ${this.bucketName}, FileName: ${fileName}`,
          'SupabaseService',
        );
        SafeLogger.error(
          `Supabase URL: ${this.configService.get<string>('SUPABASE_URL')}`,
          'SupabaseService',
        );
        throw new InternalServerErrorException(
          `Failed to upload image to Supabase: ${error.message || 'Unknown error'}`,
        );
      }

      const { data: publicUrlData } = this.supabase.storage
        .from(this.bucketName)
        .getPublicUrl(fileName);

      SafeLogger.log(
        `Image uploaded successfully to: ${publicUrlData.publicUrl}`,
        'SupabaseService',
      );
      return publicUrlData.publicUrl;
    } catch (error) {
      SafeLogger.error(
        `Image upload failed: ${error.message}`,
        'SupabaseService',
      );

      if (error instanceof BadRequestException) {
        throw error;
      }

      throw new InternalServerErrorException('Failed to upload image');
    }
  }

  /**
   * Delete image from Supabase storage
   */
  async deleteImage(imageUrl: string): Promise<void> {
    try {
      if (!imageUrl) {
        throw new BadRequestException('Image URL is required');
      }

      // Extract file path from URL
      const urlParts = imageUrl.split('/');
      const fileName = urlParts.slice(-2).join('/'); // Get folder/filename

      const { error } = await this.supabase.storage
        .from(this.bucketName)
        .remove([fileName]);

      if (error) {
        SafeLogger.error(
          `Failed to delete image: ${error.message}`,
          'SupabaseService',
        );
        throw new InternalServerErrorException(
          'Failed to delete image from storage',
        );
      }

      SafeLogger.log(
        `Image deleted successfully: ${fileName}`,
        'SupabaseService',
      );
    } catch (error) {
      SafeLogger.error(
        `Image deletion failed: ${error.message}`,
        'SupabaseService',
      );

      if (error instanceof BadRequestException) {
        throw error;
      }

      throw new InternalServerErrorException('Failed to delete image');
    }
  }

  async testConnection(): Promise<void> {
    try {
      const { data, error } = await this.supabase.storage.listBuckets();
      if (error) {
        SafeLogger.error(
          `Supabase connection test failed: ${error.message}`,
          'SupabaseService',
        );
      } else {
        SafeLogger.log(
          `Available buckets: ${data.map((b) => b.name).join(', ')}`,
          'SupabaseService',
        );
      }
    } catch (error) {
      SafeLogger.error(
        `Connection test error: ${error.message}`,
        'SupabaseService',
      );
    }
  }
}
