import { onRequest } from "firebase-functions/v2/https";
import AWS from "aws-sdk";

// Load secrets from .env
const awsAccessKey = process.env.AWS_ACCESS_KEY;
const awsSecretKey = process.env.AWS_SECRET_KEY;
const bucketName = process.env.AWS_BUCKET;

// Configure AWS
AWS.config.update({
  accessKeyId: awsAccessKey,
  secretAccessKey: awsSecretKey,
  region: "eu-west-3"
});

const s3 = new AWS.S3();

export const uploadToS3 = onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") {
      return res.status(405).json({ error: "Only POST allowed" });
    }

    const { fileName, fileDataBase64 } = req.body;

    if (!fileName || !fileDataBase64) {
      return res.status(400).json({ error: "Missing fileName or fileDataBase64" });
    }

    const buffer = Buffer.from(fileDataBase64, "base64");

    const params = {
      Bucket: bucketName,
      Key: fileName,
      Body: buffer,
      ContentType: "application/octet-stream",
    };

    const result = await s3.upload(params).promise();

    res.json({
      url: result.Location,
      key: result.Key
    });

  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});
