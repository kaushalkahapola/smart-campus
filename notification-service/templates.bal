final string verificationEmailBody = string `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Verify Your Email - FinMate</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            background: #f4f4f7;
            font-family: 'Segoe UI', sans-serif;
        }
        .email-container {
            max-width: 600px;
            margin: 40px auto;
            background: #ffffff;
            border-radius: 12px;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.07);
            overflow: hidden;
        }
        .header {
            background: #ffffff;
            text-align: center;
            padding: 40px 30px 20px;
        }
        .logo {
            font-size: 32px;
            font-weight: bold;
            letter-spacing: 1px;
            font-family: 'Segoe UI', sans-serif;
            background: linear-gradient(to right, #4f46e5, #22d3ee);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .tagline {
            font-size: 14px;
            color: #666;
            margin-top: 5px;
        }
        .content {
            padding: 30px;
            color: #333333;
        }
        .content h2 {
            font-size: 22px;
            margin-bottom: 20px;
            color: #4f46e5;
        }
        .content p {
            font-size: 16px;
            line-height: 1.6;
        }
        .verify-button {
            display: inline-block;
            margin-top: 30px;
            background: #4f46e5;
            color: white;
            padding: 14px 26px;
            text-decoration: none;
            border-radius: 6px;
            font-weight: bold;
            font-size: 15px;
        }
        .verify-button:hover {
            background: #3730a3;
        }
        .footer {
            text-align: center;
            font-size: 13px;
            color: #999999;
            padding: 25px 20px;
            background: #f0f0f0;
        }
        .footer a {
            color: #4f46e5;
            text-decoration: none;
            margin: 0 8px;
        }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <div class="logo">Fin<span style="color:#4f46e5;">Mate</span></div>
            <div class="tagline">Your Smart Financial Companion</div>
        </div>
        <div class="content">
            <h2>Verify Your Email</h2>
            <p>Hi there,</p>
            <p>Thanks for signing up with FinMate! Please confirm your email address to activate your account and start managing your finances smarter.</p>
            <a href="{{verification_link}}" class="verify-button">Verify Email Address</a>
            <p style="margin-top: 30px;">If you didn’t create this account, you can safely ignore this message.</p>
        </div>
        <div class="footer">
            &copy; 2025 FinMate. All rights reserved.<br>
            <a href="#">Privacy Policy</a> | <a href="#">Help Center</a>
        </div>
    </div>
</body>
</html>`;