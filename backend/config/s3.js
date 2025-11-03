const AWS = require('aws-sdk');
require('dotenv').config();

let cachedS3Client = null;
let cachedClientSignature = null;
let warnedForDefaultBucket = false;

const buildClientSignature = () => [
  process.env.AWS_ACCESS_KEY_ID || '',
  process.env.AWS_SECRET_ACCESS_KEY || '',
  process.env.AWS_REGION || 'us-east-1'
].join('|');

const getS3Client = () => {
  const signature = buildClientSignature();
  if (!cachedS3Client || cachedClientSignature !== signature) {
    cachedS3Client = new AWS.S3({
      accessKeyId: process.env.AWS_ACCESS_KEY_ID,
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
      region: process.env.AWS_REGION || 'us-east-1'
    });
    cachedClientSignature = signature;
  }
  return cachedS3Client;
};

const getBucketName = () => {
  const name = process.env.S3_BUCKET_NAME || 'barkpark-images';
  if ((!process.env.S3_BUCKET_NAME || name === 'barkpark-images') && !warnedForDefaultBucket) {
    console.warn('⚠️  S3_BUCKET_NAME not configured in .env, using default: barkpark-images');
    warnedForDefaultBucket = true;
  }
  return name;
};

// Upload file to S3
const uploadToS3 = async (file, folder, filename) => {
  const key = folder ? `${folder}/${filename}` : filename;
  const bucketName = getBucketName();
  const s3 = getS3Client();

  const params = {
    Bucket: bucketName,
    Key: key,
    Body: file.buffer,
    ContentType: file.mimetype
    // No ACL needed - bucket policy will handle public access
  };

  try {
    const result = await s3.upload(params).promise();
    return result.Location; // Returns the public URL
  } catch (error) {
    console.error('S3 Upload Error:', error);
    throw new Error('Failed to upload image');
  }
};

// Delete file from S3
const deleteFromS3 = async (imageUrl) => {
  const bucketName = getBucketName();
  if (!imageUrl || !bucketName || !imageUrl.includes(bucketName)) {
    return; // Not an S3 URL or invalid
  }

  // Extract key from URL
  const urlParts = imageUrl.split('/');
  const bucketIndex = urlParts.findIndex(part => part.includes(bucketName));
  if (bucketIndex === -1) {
    return;
  }
  const key = urlParts.slice(bucketIndex + 1).join('/');

  const params = {
    Bucket: bucketName,
    Key: key
  };

  const s3 = getS3Client();

  try {
    await s3.deleteObject(params).promise();
  } catch (error) {
    console.error('S3 Delete Error:', error);
    // Don't throw error - continue with operation even if delete fails
  }
};

// Generate unique filename
const generateFilename = (originalName, prefix = '') => {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 8);
  const parts = originalName.split('.');
  const extension = parts.pop();
  return `${prefix}${timestamp}-${random}.${extension}`;
};

module.exports = {
  getS3Client,
  getBucketName,
  uploadToS3,
  deleteFromS3,
  generateFilename
};

// Backwards-compatible getters for existing imports
Object.defineProperty(module.exports, 's3', {
  enumerable: true,
  get: getS3Client
});

Object.defineProperty(module.exports, 'bucketName', {
  enumerable: true,
  get: getBucketName
});
