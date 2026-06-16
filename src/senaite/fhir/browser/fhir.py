# -*- coding: utf-8 -*-

from plone.jsonapi.core.browser.decorators import handle_errors
from plone.jsonapi.core.browser.decorators import returns_binary_stream
from plone.jsonapi.core.browser.decorators import returns_json
from plone.jsonapi.core.browser.decorators import returns_xml
from Products.Five import BrowserView
from senaite.fhir.browser.decorators import runtime
from senaite.fhir.browser.interfaces import IFHIR
from senaite.fhir.browser.router import DefaultFHIRRouter
from zope.interface import implementer
from zope.publisher.interfaces import IPublishTraverse


@implementer(IFHIR, IPublishTraverse)
class FHIR(BrowserView):
    """FHIR API Framework

    Dedicated dispatcher for senaite.fhir routes. Unlike the @@API view
    from plone.jsonapi.core (which iterates all IRouter utilities), this
    view dispatches only to the local FHIR router, so the FHIR route
    table stays isolated from senaite.jsonapi.
    """

    def __init__(self, context, request):
        self.context = context
        self.request = request
        self.traverse_subpath = []

    def publishTraverse(self, request, name):
        self.traverse_subpath.append(name)
        return self

    def dispatch(self):
        path = "/".join(self.traverse_subpath)
        router = DefaultFHIRRouter
        router.initialize(self.context, self.request)
        return router(self.context, self.request, path)

    @returns_json
    @runtime
    @handle_errors
    def to_json(self):
        return self.dispatch()

    @returns_binary_stream
    def to_binary_stream(self):
        return self.dispatch()

    @returns_xml
    def to_xml(self):
        return self.dispatch()

    def __call__(self):
        accept = self.request.getHeader("Accept")
        if self.request.form.get("asbinary", False) or \
                accept == "application/zip":
            return self.to_binary_stream()
        if self.request.form.get("asxml", False) or \
                accept == "application/xml":
            return self.to_xml()
        return self.to_json()
