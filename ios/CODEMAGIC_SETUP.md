# Quick Codemagic Setup Guide for DeSo P2P

## Setup Steps

1. **Sign Up for Codemagic**
   - Go to [codemagic.io](https://codemagic.io)
   - Sign up with your GitHub/Bitbucket account

2. **Add Your App**
   - Click "Add application"
   - Select your repository
   - Choose iOS project type

3. **Configure Certificates**
   - Go to App Settings > Code Signing
   - Upload your Apple Developer account credentials
   - Codemagic will automatically manage certificates

4. **Start Build**
   - Click "Start new build"
   - Select "ios-ad-hoc" workflow
   - Start build

## Getting Your IPA

1. The build will take about 10-15 minutes
2. Once complete, you'll receive an email with the IPA file
3. Download and distribute to your registered devices

## Troubleshooting

- Make sure your Apple Developer account has enough device slots
- Verify all UDIDs are registered in your account
- Check build logs for any code signing issues

For urgent builds, contact Codemagic support via their live chat.
