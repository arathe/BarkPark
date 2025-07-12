// This test file tests the S3 utilities
// AWS SDK is already mocked globally in setup.js

const { uploadToS3, deleteFromS3, generateFilename } = require('../../config/s3');
const AWS = require('aws-sdk');

describe('S3 Upload Utilities - Error Handling & Recovery', () => {
  let mockS3Instance;
  let mockUpload;
  let mockDeleteObject;
  const mockFile = {
    buffer: Buffer.from('test image data'),
    mimetype: 'image/jpeg',
    originalname: 'test.jpg'
  };
  
  beforeEach(() => {
    // Clear all mocks
    jest.clearAllMocks();
    
    // Get the mocked S3 instance
    mockS3Instance = new AWS.S3();
    mockUpload = mockS3Instance.upload;
    mockDeleteObject = mockS3Instance.deleteObject;
    
    // Set up environment variables
    process.env.S3_BUCKET_NAME = 'test-bucket';
    process.env.AWS_ACCESS_KEY_ID = 'test-key';
    process.env.AWS_SECRET_ACCESS_KEY = 'test-secret';
  });

  describe('uploadToS3', () => {
    const mockFile = {
      buffer: Buffer.from('test image data'),
      mimetype: 'image/jpeg',
      originalname: 'test.jpg'
    };

    test('should upload file successfully', async () => {
      const mockLocation = 'https://test-bucket.s3.amazonaws.com/dogs/123456-abc123.jpg';
      mockUpload().promise.mockResolvedValue({
        Location: mockLocation,
        ETag: '"abc123"',
        Key: 'dogs/123456-abc123.jpg'
      });

      const result = await uploadToS3(mockFile, 'dogs', '123456-abc123.jpg');

      expect(result).toBe(mockLocation);
      expect(mockUpload).toHaveBeenCalledWith({
        Bucket: 'test-bucket',
        Key: 'dogs/123456-abc123.jpg',
        Body: mockFile.buffer,
        ContentType: 'image/jpeg'
      });
    });

    test('should handle upload failure', async () => {
      const mockError = new Error('Network error');
      mockUpload().promise.mockRejectedValue(mockError);

      await expect(uploadToS3(mockFile, 'dogs', '123456-abc123.jpg'))
        .rejects.toThrow('Failed to upload image');
    });

    test('should handle AWS credential errors', async () => {
      const mockError = new Error('Invalid credentials');
      mockError.code = 'CredentialsError';
      mockUpload().promise.mockRejectedValue(mockError);

      await expect(uploadToS3(mockFile, 'dogs', '123456-abc123.jpg'))
        .rejects.toThrow('Failed to upload image');
    });

    test('should handle rate limiting', async () => {
      const mockError = new Error('Too Many Requests');
      mockError.code = 'RequestLimitExceeded';
      mockUpload().promise.mockRejectedValue(mockError);

      await expect(uploadToS3(mockFile, 'dogs', '123456-abc123.jpg'))
        .rejects.toThrow('Failed to upload image');
    });

    test('should upload different file types', async () => {
      const fileTypes = [
        { mimetype: 'image/png', extension: 'png' },
        { mimetype: 'image/webp', extension: 'webp' },
        { mimetype: 'image/jpeg', extension: 'jpg' }
      ];

      for (const fileType of fileTypes) {
        const file = {
          ...mockFile,
          mimetype: fileType.mimetype,
          originalname: `test.${fileType.extension}`
        };

        mockUpload().promise.mockResolvedValue({
          Location: `https://test-bucket.s3.amazonaws.com/dogs/test.${fileType.extension}`
        });

        const result = await uploadToS3(file, 'dogs', `test.${fileType.extension}`);
        expect(result).toContain(fileType.extension);
      }
    });

    test('should handle large files', async () => {
      const largeFile = {
        buffer: Buffer.alloc(5 * 1024 * 1024), // 5MB
        mimetype: 'image/jpeg',
        originalname: 'large.jpg'
      };

      mockUpload().promise.mockResolvedValue({
        Location: 'https://test-bucket.s3.amazonaws.com/dogs/large.jpg'
      });

      await expect(uploadToS3(largeFile, 'dogs', 'large.jpg')).resolves.toBeDefined();
    });

    test('should handle concurrent uploads', async () => {
      mockUpload().promise.mockResolvedValue({
        Location: 'https://test-bucket.s3.amazonaws.com/dogs/concurrent.jpg'
      });

      const uploads = Array(5).fill(null).map((_, index) => 
        uploadToS3(mockFile, 'dogs', `concurrent-${index}.jpg`)
      );

      const results = await Promise.all(uploads);
      expect(results).toHaveLength(5);
      expect(mockUpload).toHaveBeenCalledTimes(5);
    });
  });

  describe('deleteFromS3', () => {
    test('should delete file successfully', async () => {
      mockDeleteObject().promise.mockResolvedValue({
        DeleteMarker: true,
        VersionId: '12345'
      });

      const imageUrl = 'https://test-bucket.s3.amazonaws.com/dogs/123456-abc123.jpg';
      await deleteFromS3(imageUrl);

      expect(mockDeleteObject).toHaveBeenCalledWith({
        Bucket: 'test-bucket',
        Key: 'dogs/123456-abc123.jpg'
      });
    });

    test('should handle deletion failure silently', async () => {
      mockDeleteObject().promise.mockRejectedValue(new Error('Access Denied'));

      const imageUrl = 'https://test-bucket.s3.amazonaws.com/dogs/123456-abc123.jpg';
      
      // Should not throw
      await expect(deleteFromS3(imageUrl)).resolves.toBeUndefined();
    });

    test('should handle invalid URLs', async () => {
      const invalidUrls = [
        null,
        undefined,
        '',
        'not-a-url',
        'https://different-bucket.s3.amazonaws.com/image.jpg',
        'https://example.com/image.jpg'
      ];

      for (const url of invalidUrls) {
        await deleteFromS3(url);
        expect(mockDeleteObject).not.toHaveBeenCalled();
        jest.clearAllMocks();
      }
    });

    test('should extract key correctly from various URL formats', async () => {
      mockDeleteObject().promise.mockResolvedValue({});

      const urlFormats = [
        {
          url: 'https://test-bucket.s3.amazonaws.com/dogs/profile/123.jpg',
          expectedKey: 'dogs/profile/123.jpg'
        },
        {
          url: 'https://s3.amazonaws.com/test-bucket/dogs/123.jpg',
          expectedKey: 'dogs/123.jpg'
        },
        {
          url: 'https://test-bucket.s3.us-east-1.amazonaws.com/dogs/123.jpg',
          expectedKey: 'dogs/123.jpg'
        }
      ];

      for (const format of urlFormats) {
        await deleteFromS3(format.url);
        expect(mockDeleteObject).toHaveBeenCalledWith({
          Bucket: 'test-bucket',
          Key: format.expectedKey
        });
        jest.clearAllMocks();
      }
    });

    test('should handle concurrent deletions', async () => {
      mockDeleteObject().promise.mockResolvedValue({});

      const urls = Array(5).fill(null).map((_, index) => 
        `https://test-bucket.s3.amazonaws.com/dogs/image-${index}.jpg`
      );

      await Promise.all(urls.map(url => deleteFromS3(url)));
      
      expect(mockDeleteObject).toHaveBeenCalledTimes(5);
    });
  });

  describe('generateFilename', () => {
    test('should generate unique filename', () => {
      const filename1 = generateFilename('test.jpg', 'dog_');
      const filename2 = generateFilename('test.jpg', 'dog_');

      expect(filename1).not.toBe(filename2);
      expect(filename1).toMatch(/^dog_\d+-[a-z0-9]{6}\.jpg$/);
    });

    test('should preserve file extension', () => {
      const extensions = ['jpg', 'jpeg', 'png', 'webp', 'JPEG', 'PNG'];

      for (const ext of extensions) {
        const filename = generateFilename(`test.${ext}`);
        expect(filename).toMatch(new RegExp(`\\.${ext}$`));
      }
    });

    test('should handle files without extension', () => {
      const filename = generateFilename('test');
      expect(filename).toMatch(/^\d+-[a-z0-9]{6}\.test$/);
    });

    test('should handle files with multiple dots', () => {
      const filename = generateFilename('test.image.backup.jpg');
      expect(filename).toMatch(/\.jpg$/);
    });

    test('should generate collision-resistant names', () => {
      const filenames = new Set();
      
      // Generate many filenames
      for (let i = 0; i < 1000; i++) {
        filenames.add(generateFilename('test.jpg'));
      }

      // All should be unique
      expect(filenames.size).toBe(1000);
    });
  });

  describe('Error Recovery Scenarios', () => {
    test('should handle S3 service unavailable', async () => {
      const mockError = new Error('Service Unavailable');
      mockError.statusCode = 503;
      mockUpload().promise.mockRejectedValue(mockError);

      await expect(uploadToS3(mockFile, 'dogs', 'test.jpg'))
        .rejects.toThrow('Failed to upload image');
    });

    test('should handle bucket not found', async () => {
      const mockError = new Error('NoSuchBucket');
      mockError.code = 'NoSuchBucket';
      mockUpload().promise.mockRejectedValue(mockError);

      await expect(uploadToS3(mockFile, 'dogs', 'test.jpg'))
        .rejects.toThrow('Failed to upload image');
    });

    test('should handle permission denied', async () => {
      const mockError = new Error('Access Denied');
      mockError.code = 'AccessDenied';
      mockUpload().promise.mockRejectedValue(mockError);

      await expect(uploadToS3(mockFile, 'dogs', 'test.jpg'))
        .rejects.toThrow('Failed to upload image');
    });

    test('should handle network timeout', async () => {
      const mockError = new Error('Request timeout');
      mockError.code = 'RequestTimeout';
      mockUpload().promise.mockRejectedValue(mockError);

      await expect(uploadToS3(mockFile, 'dogs', 'test.jpg'))
        .rejects.toThrow('Failed to upload image');
    });
  });

  describe('Edge Cases', () => {
    test('should handle empty file buffer', async () => {
      const emptyFile = {
        buffer: Buffer.alloc(0),
        mimetype: 'image/jpeg'
      };

      mockUpload().promise.mockResolvedValue({
        Location: 'https://test-bucket.s3.amazonaws.com/dogs/empty.jpg'
      });

      await uploadToS3(emptyFile, 'dogs', 'empty.jpg');
      
      expect(mockUpload).toHaveBeenCalledWith(
        expect.objectContaining({
          Body: expect.any(Buffer)
        })
      );
    });

    test('should handle special characters in filename', () => {
      const specialNames = [
        'test image (1).jpg',
        'test@image.jpg',
        'test#image.jpg',
        'test image.jpg',
        'тест.jpg',
        '测试.jpg'
      ];

      for (const name of specialNames) {
        const filename = generateFilename(name);
        // Should still end with the original extension
        expect(filename).toMatch(/\.jpg$/);
        // Should not contain special characters except dots and dashes
        expect(filename).toMatch(/^[\w\d-]+\.jpg$/);
      }
    });

    test('should handle missing environment variables', async () => {
      delete process.env.S3_BUCKET_NAME;
      
      // Should still attempt upload but with undefined bucket
      mockUpload().promise.mockRejectedValue(new Error('Bucket name missing'));
      
      await expect(uploadToS3(mockFile, 'dogs', 'test.jpg'))
        .rejects.toThrow('Failed to upload image');
    });
  });
});