from django.http import JsonResponse, HttpResponse
from django.conf import settings


def healthcheck(request):
    return JsonResponse({"status": "ok"})


def get_version(request):
    return JsonResponse({"version": settings.VERSION})
