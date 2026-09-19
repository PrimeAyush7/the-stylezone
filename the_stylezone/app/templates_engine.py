import inspect
from pathlib import Path
from starlette.templating import Jinja2Templates as StarletteJinja2Templates
from starlette.requests import Request

class Jinja2Templates(StarletteJinja2Templates):
    """
    Universal Jinja2Templates class compatible with both:
    - Newer Starlette (>=0.28): TemplateResponse(request=request, name="...", context=..., status_code=...)
    - Older Starlette (<=0.26): TemplateResponse(name="...", context=..., status_code=...)
    """
    def TemplateResponse(self, *args, **kwargs):
        sig = inspect.signature(StarletteJinja2Templates.TemplateResponse)
        
        # If the installed Starlette version has 'request' in its parameters, pass through
        if 'request' in sig.parameters:
            return super().TemplateResponse(*args, **kwargs)
        
        # Legacy Starlette adapter:
        request = kwargs.pop('request', None)
        name = kwargs.pop('name', None)
        context = kwargs.pop('context', None)
        status_code = kwargs.pop('status_code', 200)

        # Handle positional args if any were passed
        if args:
            if isinstance(args[0], Request):
                request = args[0]
                name = args[1] if len(args) > 1 else name
                context = args[2] if len(args) > 2 else context
            elif isinstance(args[0], str):
                name = args[0]
                context = args[1] if len(args) > 1 else context

        if context is None:
            context = {}
        if request is not None and 'request' not in context:
            context['request'] = request

        return super().TemplateResponse(name, context, status_code=status_code, **kwargs)
