import asyncio
import logging
from cli import start_cli

async def main():
    """Main entry point for the Deso P2P application"""
    # Setup logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    logger = logging.getLogger(__name__)

    try:
        # Start the CLI in the default event loop
        logger.info("Starting Deso P2P application...")
        await asyncio.get_event_loop().run_in_executor(None, start_cli)
    except Exception as e:
        logger.error(f"Application error: {str(e)}")
        raise

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nShutting down gracefully...")
    except Exception as e:
        print(f"\nApplication terminated due to error: {str(e)}")