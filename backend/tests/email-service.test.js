const nodemailer = require('nodemailer');

// EmailService is a singleton, so we need to re-require it after mocks are set up
// The global mock in setup.js handles nodemailer

describe('EmailService', () => {
  let emailService;

  beforeEach(() => {
    // Clear the module cache so we get a fresh instance
    jest.resetModules();

    // Re-set env vars
    process.env.NODE_ENV = 'test';
    process.env.SMTP_HOST = 'smtp.test.com';
    process.env.SMTP_PORT = '587';
    process.env.SMTP_SECURE = 'false';
    process.env.SMTP_USER = 'testuser';
    process.env.SMTP_PASS = 'testpass';
    process.env.SMTP_FROM = 'test@barkpark.app';
    process.env.APP_URL = 'https://test.barkpark.app';

    // Re-require to get fresh instance with our env vars
    emailService = require('../services/emailService');
  });

  afterEach(() => {
    // Clean up env vars
    delete process.env.SMTP_HOST;
    delete process.env.SMTP_PORT;
    delete process.env.SMTP_SECURE;
    delete process.env.SMTP_USER;
    delete process.env.SMTP_PASS;
    delete process.env.SMTP_FROM;
    delete process.env.APP_URL;
  });

  describe('sendPasswordResetEmail', () => {
    it('should send password reset email successfully', async () => {
      const result = await emailService.sendPasswordResetEmail(
        'user@example.com',
        'A3B7K'
      );

      expect(result).toBeDefined();
      expect(result.success).toBe(true);
      expect(result.messageId).toBeDefined();
    });

    it('should call sendMail with correct parameters', async () => {
      // Get the transporter that emailService is actually using
      const transporter = emailService.transporter;

      await emailService.sendPasswordResetEmail(
        'user@example.com',
        'XY9Z1'
      );

      expect(transporter.sendMail).toHaveBeenCalled();

      const callArgs = transporter.sendMail.mock.calls[0][0];
      expect(callArgs.to).toBe('user@example.com');
      expect(callArgs.subject).toContain('Reset');
      expect(callArgs.html).toContain('XY9Z1');
      expect(callArgs.text).toContain('XY9Z1');
    });
  });

  describe('getPasswordResetTemplate', () => {
    it('should include the reset token in HTML template', () => {
      const html = emailService.getPasswordResetTemplate('A3B7K', 'https://example.com/reset?token=A3B7K');
      expect(html).toContain('A3B7K');
      expect(html).toContain('Reset Your Password');
      expect(html).toContain('BarkPark');
      expect(html).toContain('1 hour');
    });

    it('should include step-by-step instructions', () => {
      const html = emailService.getPasswordResetTemplate('A3B7K', 'https://example.com/reset');
      expect(html).toContain('Open the BarkPark app');
      expect(html).toContain('Forgot Password');
    });
  });

  describe('getPasswordResetTextTemplate', () => {
    it('should include the reset token in text template', () => {
      const text = emailService.getPasswordResetTextTemplate('A3B7K', 'https://example.com/reset?token=A3B7K');
      expect(text).toContain('A3B7K');
      expect(text).toContain('Reset Your BarkPark Password');
      expect(text).toContain('1 hour');
    });
  });

  describe('constructor configuration', () => {
    it('should use SMTP configuration when SMTP_HOST is set', () => {
      // The constructor already ran with SMTP_HOST set
      expect(emailService.isTestMode).toBe(false);
      expect(emailService.transporter).toBeDefined();
    });

    it('should use configured from email', () => {
      expect(emailService.fromEmail).toBe('test@barkpark.app');
    });

    it('should use configured app URL', () => {
      expect(emailService.appUrl).toBe('https://test.barkpark.app');
    });

    it('should use default from email when not configured', () => {
      jest.resetModules();
      delete process.env.SMTP_FROM;
      delete process.env.SMTP_HOST;
      process.env.NODE_ENV = 'development';
      const freshService = require('../services/emailService');
      expect(freshService.fromEmail).toBe('noreply@barkpark.app');
    });
  });

  describe('sendEmail (generic method)', () => {
    it('should send a generic email', async () => {
      const result = await emailService.sendEmail(
        'recipient@example.com',
        'Test Subject',
        '<h1>Hello</h1>',
        'Hello'
      );

      expect(result).toBeDefined();
    });
  });
});
