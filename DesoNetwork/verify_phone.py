from twilio.rest import Client

def verify_phone_number(phone_number: str):
    """Verify a phone number using Twilio Verify API"""
    # Use the same credentials
    account_sid = "AC2a1cc5d79b325c5c825b9d1cdf28450d"
    auth_token = "c5ed2e46b88feb17be95abb5dd3f282b"
    
    client = Client(account_sid, auth_token)
    
    try:
        # Format the phone number to E.164 format if not already
        if not phone_number.startswith('+'):
            phone_number = '+1' + phone_number
            
        # Create a verification service if it doesn't exist
        service = client.verify.v2.services.create(
            friendly_name='DeSo P2P Phone Verification'
        )
        
        # Send verification code
        verification = client.verify.v2.services(service.sid).verifications.create(
            to=phone_number,
            channel='sms'
        )
        
        print(f"Verification code sent to {phone_number}")
        print("Please enter the verification code when you receive it:")
        
        # Get verification code from user input
        code = input().strip()
        
        # Check verification code
        verification_check = client.verify.v2.services(service.sid).verification_checks.create(
            to=phone_number,
            code=code
        )
        
        if verification_check.status == 'approved':
            print("Phone number verified successfully!")
            return True
        else:
            print("Verification failed. Please try again.")
            return False
            
    except Exception as e:
        print(f"Error during verification: {str(e)}")
        return False

if __name__ == "__main__":
    phone_number = "6266804358"  # The number provided
    verify_phone_number(phone_number)
