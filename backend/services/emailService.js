const nodemailer = require('nodemailer');

class EmailService {
  constructor() {
    // Initialize transporter with environment variables
    // In development, we'll use ethereal email for testing
    if (process.env.NODE_ENV === 'development' && !process.env.SMTP_HOST) {
      // For development, we'll create a test account on demand
      this.transporter = null;
      this.isTestMode = true;
    } else {
      this.transporter = nodemailer.createTransporter({
        host: process.env.SMTP_HOST,
        port: parseInt(process.env.SMTP_PORT, 10) || 587,
        secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
        auth: {
          user: process.env.SMTP_USER,
          pass: process.env.SMTP_PASS
        }
      });
      this.isTestMode = false;
    }

    this.fromEmail = process.env.SMTP_FROM || 'noreply@barkpark.app';
    this.appName = 'BarkPark';
    this.appUrl = process.env.APP_URL || 'https://barkpark.app';
  }

  async getTestTransporter() {
    if (!this.transporter && this.isTestMode) {
      // Create a test account
      const testAccount = await nodemailer.createTestAccount();
      
      this.transporter = nodemailer.createTransporter({
        host: 'smtp.ethereal.email',
        port: 587,
        secure: false,
        auth: {
          user: testAccount.user,
          pass: testAccount.pass
        }
      });
    }
    return this.transporter;
  }

  async sendPasswordResetEmail(email, resetToken) {
    try {
      const transporter = this.isTestMode ? await this.getTestTransporter() : this.transporter;
      
      // For mobile app, we'll use a deep link or have users enter the token manually
      const resetUrl = `${this.appUrl}/reset-password?token=${resetToken}`;
      
      const mailOptions = {
        from: `${this.appName} <${this.fromEmail}>`,
        to: email,
        subject: 'Reset Your BarkPark Password',
        html: this.getPasswordResetTemplate(resetToken, resetUrl),
        text: this.getPasswordResetTextTemplate(resetToken, resetUrl)
      };

      const info = await transporter.sendMail(mailOptions);
      
      if (this.isTestMode) {
        console.log('Test email sent: %s', info.messageId);
        console.log('Preview URL: %s', nodemailer.getTestMessageUrl(info));
      }
      
      return {
        success: true,
        messageId: info.messageId,
        previewUrl: this.isTestMode ? nodemailer.getTestMessageUrl(info) : null
      };
    } catch (error) {
      console.error('Error sending password reset email:', error);
      throw new Error('Failed to send password reset email');
    }
  }

  getPasswordResetTemplate(token, resetUrl) {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Reset Your Password</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
          }
          .container {
            background-color: white;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
          }
          .header {
            text-align: center;
            margin-bottom: 30px;
          }
          .logo {
            font-size: 32px;
            font-weight: bold;
            color: #FF6B6B;
          }
          .content {
            margin-bottom: 30px;
          }
          .token-box {
            background-color: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 5px;
            padding: 15px;
            margin: 20px 0;
            text-align: center;
            font-family: monospace;
            font-size: 24px;
            letter-spacing: 2px;
            color: #495057;
            word-break: break-all;
          }
          .button {
            display: inline-block;
            padding: 12px 30px;
            background-color: #FF6B6B;
            color: white;
            text-decoration: none;
            border-radius: 25px;
            font-weight: bold;
            margin: 20px 0;
          }
          .footer {
            text-align: center;
            font-size: 12px;
            color: #666;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <div class="logo">🐕 BarkPark</div>
          </div>
          
          <div class="content">
            <h2>Reset Your Password</h2>
            <p>We received a request to reset your BarkPark password. Use the code below in the app to create a new password:</p>
            
            <div class="token-box">
              ${token}
            </div>
            
            <p><strong>This code will expire in 1 hour.</strong></p>
            
            <p>To reset your password:</p>
            <ol>
              <li>Open the BarkPark app</li>
              <li>Tap "Forgot Password" on the login screen</li>
              <li>Enter your email and this code</li>
              <li>Create your new password</li>
            </ol>
            
            <p>If you didn't request this password reset, you can safely ignore this email. Your password won't be changed.</p>
          </div>
          
          <div class="footer">
            <p>This email was sent by BarkPark. Please do not reply to this email.</p>
            <p>© ${new Date().getFullYear()} BarkPark. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  getPasswordResetTextTemplate(token, resetUrl) {
    return `
Reset Your BarkPark Password

We received a request to reset your BarkPark password. Use the code below in the app to create a new password:

Reset Code: ${token}

This code will expire in 1 hour.

To reset your password:
1. Open the BarkPark app
2. Tap "Forgot Password" on the login screen
3. Enter your email and this code
4. Create your new password

If you didn't request this password reset, you can safely ignore this email. Your password won't be changed.

This email was sent by BarkPark. Please do not reply to this email.
© ${new Date().getFullYear()} BarkPark. All rights reserved.
    `.trim();
  }

  async sendWelcomeEmail(email, firstName) {
    // Placeholder for future welcome email functionality
    // Could be implemented when user verification is added
  }

  async sendEmail(to, subject, html, text) {
    // Generic email sending method for future use
    const transporter = this.isTestMode ? await this.getTestTransporter() : this.transporter;
    
    const mailOptions = {
      from: `${this.appName} <${this.fromEmail}>`,
      to,
      subject,
      html,
      text
    };

    return await transporter.sendMail(mailOptions);
  }
}

// Export singleton instance
module.exports = new EmailService();