const AWS = require('aws-sdk');
require('dotenv').config();

// Configure AWS S3
const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION || 'us-east-1'
});

const bucketName = process.env.S3_BUCKET_NAME;

// Upload file to S3
const uploadToS3 = async (file, folder, filename) => {
  const key = `${folder}/${filename}`;
  
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
  if (!imageUrl || !imageUrl.includes(bucketName)) {
    return; // Not an S3 URL or invalid
  }

  // Extract key from URL
  const urlParts = imageUrl.split('/');
  const bucketIndex = urlParts.findIndex(part => part.includes(bucketName));
  const key = urlParts.slice(bucketIndex + 1).join('/');

  const params = {
    Bucket: bucketName,
    Key: key
  };

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
  const extension = originalName.split('.').pop();
  return `${prefix}${timestamp}-${random}.${extension}`;
};

module.exports = {
  s3,
  bucketName,
  uploadToS3,
  deleteFromS3,
  generateFilename
};