Reportable analyses and Observation generation
----------------------------------------------

Not every Analysis of a Sample becomes an ``Observation``. ``is_reportable``
decides which ones do, and the decision propagates to everything built out
of it: ``DiagnosticReport.result`` and, in turn, the ``Observation``
entries served by ``_include=Observation:result``.

An Analysis is reportable when all of the following hold:

- it is not hidden
- it is not for internal use
- its status is one of ``ANALYSIS_REPORTABLE_STATUSES``

Running this test from the buildout directory:

    bin/test test_doctests -t observation_reportable


Test Setup
~~~~~~~~~~

Needed imports:

    >>> import json
    >>> import uuid
    >>> import transaction
    >>> from DateTime import DateTime
    >>> from plone.app.testing import setRoles
    >>> from plone.app.testing import TEST_USER_ID
    >>> from zope.interface import alsoProvides
    >>> from zope.interface import noLongerProvides
    >>> from bika.lims import api
    >>> from bika.lims.interfaces import IInternalUse
    >>> from bika.lims.utils.analysisrequest import create_analysisrequest
    >>> from bika.lims.workflow import doActionFor as do_action_for
    >>> from senaite.fhir import api as fapi
    >>> from senaite.fhir.config import ANALYSIS_REPORTABLE_STATUSES

Functional helpers:

    >>> def get_analysis(sample, keyword):
    ...     for analysis in sample.getAnalyses(full_objects=True):
    ...         if analysis.getKeyword() == keyword:
    ...             return analysis
    ...     return None

    >>> def get_status(analysis):
    ...     return api.get_review_status(analysis)

Variables:

    >>> portal = self.portal
    >>> request = self.request
    >>> setup = portal.setup
    >>> portal_url = portal.absolute_url()
    >>> fhir_url = "{}/@@FHIR/r5".format(portal_url)
    >>> browser = self.getBrowser()
    >>> setRoles(portal, TEST_USER_ID, ["LabManager", "Manager"])
    >>> portal.bika_setup.setSelfVerificationEnabled(True)
    >>> transaction.commit()


Setup objects
~~~~~~~~~~~~~

    >>> client = api.create(portal.clients, "Client",
    ...                     Name="Green Valley", ClientID="GV")
    >>> contact = api.create(client, "Contact",
    ...                      Firstname="Ana", Lastname="Lima")
    >>> sampletype = api.create(setup.sampletypes, "SampleType",
    ...                         title="Blood", Prefix="B")
    >>> labcontact = api.create(portal.bika_setup.bika_labcontacts,
    ...                         "LabContact", Firstname="Lab",
    ...                         Lastname="Chief")
    >>> department = api.create(setup.departments, "Department",
    ...                         title="Haematology", Manager=labcontact)
    >>> category = api.create(setup.analysiscategories, "AnalysisCategory",
    ...                       title="CBC", Department=department)

    >>> def new_service(title, keyword):
    ...     return api.create(portal.bika_setup.bika_analysisservices,
    ...                       "AnalysisService", title=title, Keyword=keyword,
    ...                       Category=category.UID())

    >>> Hb = new_service("Haemoglobin", "Hb")
    >>> Fe = new_service("Iron", "Fe")
    >>> Au = new_service("Gold", "Au")
    >>> Cu = new_service("Copper", "Cu")

    >>> def new_sample(services):
    ...     values = {
    ...         "Client": client.UID(),
    ...         "Contact": contact.UID(),
    ...         "DateSampled": DateTime().strftime("%Y-%m-%d"),
    ...         "SampleType": sampletype.UID(),
    ...     }
    ...     uids = map(api.get_uid, services)
    ...     return create_analysisrequest(client, request, values, uids)


Only some statuses are reportable
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    >>> sorted(ANALYSIS_REPORTABLE_STATUSES)
    ['published', 'to_be_verified', 'verified']

Register a sample and take each of its analyses to a different status:

    >>> sample = new_sample([Hb, Fe, Au, Cu])
    >>> _ = do_action_for(sample, "receive")

An analysis with no result submitted yet is not reportable:

    >>> gold = get_analysis(sample, "Au")
    >>> get_status(gold)
    'unassigned'

    >>> fapi.is_reportable(gold)
    False

Once the result is submitted, it becomes reportable:

    >>> haemoglobin = get_analysis(sample, "Hb")
    >>> haemoglobin.setResult(14)
    >>> _ = do_action_for(haemoglobin, "submit")
    >>> get_status(haemoglobin)
    'to_be_verified'

    >>> fapi.is_reportable(haemoglobin)
    True

And it remains reportable once verified:

    >>> iron = get_analysis(sample, "Fe")
    >>> iron.setResult(5)
    >>> _ = do_action_for(iron, "submit")
    >>> _ = do_action_for(iron, "verify")
    >>> get_status(iron)
    'verified'

    >>> fapi.is_reportable(iron)
    True

A retracted analysis is not reportable anymore, and neither is the retest
it generates, until a result is submitted for it:

    >>> copper = get_analysis(sample, "Cu")
    >>> copper.setResult(3)
    >>> _ = do_action_for(copper, "submit")
    >>> _ = do_action_for(copper, "retract")
    >>> get_status(copper)
    'retracted'

    >>> fapi.is_reportable(copper)
    False

    >>> retest = copper.getRetest()
    >>> get_status(retest)
    'unassigned'

    >>> fapi.is_reportable(retest)
    False


Hidden analyses are not reportable
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Hiding an analysis makes it non-reportable, regardless of its status:

    >>> get_status(iron)
    'verified'

    >>> iron.setHidden(True)
    >>> fapi.is_reportable(iron)
    False

Unhiding it restores it:

    >>> iron.setHidden(False)
    >>> fapi.is_reportable(iron)
    True


Analyses for internal use are not reportable
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

An analysis marked for internal use is not reportable either, regardless
of its status:

    >>> alsoProvides(iron, IInternalUse)
    >>> fapi.is_reportable(iron)
    False

    >>> noLongerProvides(iron, IInternalUse)
    >>> fapi.is_reportable(iron)
    True


DiagnosticReport.result only references reportable analyses
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The Observations of the report are built out of the reportable analyses
only. With the sample above, only the submitted and the verified analyses
qualify:

    >>> analyses = sample.getAnalyses(full_objects=True)
    >>> sorted([an.getKeyword() for an in analyses if fapi.is_reportable(an)])
    ['Fe', 'Hb']

    >>> report = api.create(sample, "ResultsReport", sample=sample.UID())
    >>> report.setPdf({
    ...     "data": b"%PDF-1.4 fake report",
    ...     "filename": u"report.pdf",
    ...     "contentType": "application/pdf",
    ... })

    >>> dr = fapi.to_fhir_resource(report)
    >>> references = [res["reference"] for res in dict(dr)["result"]]
    >>> len(references)
    2

    >>> expected = sorted([
    ...     "Observation/{}".format(fapi.get_uuid(an))
    ...     for an in analyses if fapi.is_reportable(an)])
    >>> sorted(references) == expected
    True

The hidden and the internal use analyses are left out here as well:

    >>> iron.setHidden(True)
    >>> dr = fapi.to_fhir_resource(report)
    >>> references = [res["reference"] for res in dict(dr)["result"]]
    >>> references == [
    ...     "Observation/{}".format(fapi.get_uuid(haemoglobin))]
    True

    >>> iron.setHidden(False)
    >>> alsoProvides(iron, IInternalUse)
    >>> len(dict(fapi.to_fhir_resource(report))["result"])
    1

    >>> noLongerProvides(iron, IInternalUse)
    >>> len(dict(fapi.to_fhir_resource(report))["result"])
    2


The search bundle includes exactly those Observations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``_include=Observation:result`` resolves the references above, so the
non-reportable analyses never reach the bundle:

    >>> transaction.commit()
    >>> url = "{}/DiagnosticReport?_summary=true&_include=Observation:result"
    >>> browser.open(url.format(fhir_url))
    >>> bundle = json.loads(browser.contents)

    >>> included = sorted(entry["resource"]["id"]
    ...                   for entry in bundle["entry"]
    ...                   if entry["search"]["mode"] == "include")
    >>> len(included)
    2

    >>> included == sorted([str(fapi.get_uuid(an))
    ...                     for an in analyses if fapi.is_reportable(an)])
    True

None of the non-reportable analyses is served:

    >>> non_reportable = [an for an in analyses
    ...                   if not fapi.is_reportable(an)]
    >>> sorted([an.getKeyword() for an in non_reportable])
    ['Au', 'Cu', 'Cu']

    >>> any(str(fapi.get_uuid(an)) in included for an in non_reportable)
    False
