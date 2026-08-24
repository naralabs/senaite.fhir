# -*- coding: utf-8 -*-

from senaite.app.listing.utils import add_review_state
from senaite.fhir import _
from senaite.app.listing.interfaces import IListingView
from senaite.app.listing.interfaces import IListingViewAdapter
from zope.component import adapter
from zope.interface import implementer


@adapter(IListingView)
@implementer(IListingViewAdapter)
class WorksheetsListingAdapter(object):
    """Add FHIR instrument-worklist states to the worksheet listing."""

    def __init__(self, listing, context):
        self.listing = listing
        self.context = context

    def before_render(self):
        """Add the FHIR worksheet state filters to the listing."""
        self.add_review_states()

    def folder_item(self, obj, item, index):
        return item

    def get_status_info(self, state_id, title):
        """Build the listing configuration for a FHIR worksheet state."""
        return {
            "id": state_id,
            "title": title,
            "contentFilter": {
                "review_state": state_id,
                "sort_on": "created",
                "sort_order": "reverse",
            },
            "transitions": [],
            "custom_transitions": [],
            "columns": self.listing.columns.keys(),
        }

    def add_review_states(self):
        """Adds fhir-specific review states (filter buttons) in the listing
        """
        add_review_state(
            self.listing,
            self.get_status_info("ready", _("Ready")),
            before="to_be_verified",
        )
        add_review_state(
            self.listing,
            self.get_status_info("in_progress", _("In progress")),
            before="to_be_verified",
        )

        # The aggregate filters must include the intermediate states too.
        for state_id in ["default", "all", "mine"]:
            state = self.listing.get_review_state(state_id)
            if not state:
                continue
            review_states = state["contentFilter"]["review_state"]
            for fhir_state in ["ready", "in_progress"]:
                if fhir_state not in review_states:
                    review_states.append(fhir_state)
