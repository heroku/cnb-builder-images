from typing import Any

from salesforce_functions import Context, InvocationEvent, get_logger

# The type of the data payload sent with the invocation event.
# Change this to a more specific type matching the expected payload for
# improved IDE auto-completion and linting coverage. For example:
# `EventPayloadType = dict[str, Any]`
EventPayloadType = Any

logger = get_logger()


async def function(event: InvocationEvent[EventPayloadType], context: Context):
    """Describe the function here."""

    result = await context.org.data_api.query("SELECT Id, Name FROM Account")
    logger.info(f"Function successfully queried {result.total_size} account records!")

    return result.records
