# Setting Up SSH Access for GitHub

## Important Security Notice
- Never share your SSH keys
- Never commit SSH keys to repositories
- Keep your private key secure

## Setup Steps for Mobile (GitHub iOS App)

1. **Generate SSH Key (on your device)**
   ```bash
   # DO NOT share the output of these commands
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. **Add to GitHub**
   - Go to GitHub Settings → SSH and GPG keys
   - Click "New SSH key"
   - Add your public key (the .pub file content)

3. **Test Connection**
   ```bash
   # Test your connection
   ssh -T git@github.com
   ```

## Security Best Practices
- Use a strong passphrase
- Keep private keys secure
- Regularly rotate keys
- Use different keys for different services

## For More Help
Visit GitHub's official documentation:
https://docs.github.com/en/authentication/connecting-to-github-with-ssh
