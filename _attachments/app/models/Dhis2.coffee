class Dhis2
  constructor: (options) ->
    _(options).each (value, name) =>
      @[name] = value

  request: (options) =>
    options.data = JSON.stringify(options.data) if options.method is "POST"
    $.ajax
      url: "#{@dhis2Url}/api/#{options.api}.json"
      username: @username
      password: @password
      method: options.method or "GET"
      contentType: "application/json"
      xhrFields:
        withCredentials: true
      data: options.data
      error: (error) -> console.log error
      success: (response) -> options.success(response)

  trackedEntityInstanceIdForCaseId: (options) =>
    @request
      api: "trackedEntityInstances"
      data:
        ou: options.organisationUnit
        program: @programId
        filter: "#{@caseIdAttributeId}:LIKE:#{options.caseId}"
      error: (error) -> console.log error
      success: (response) ->
        return options.success(null) if response.rows.length is 0
          #Create new tracked entity
        if response.rows.length > 1
          console.warn "More than one match in DHIS2 for #{options.caseId}"
        options.success(response.rows[0])

  createTrackedEntityInstance: (options) =>
    @request
      api: "trackedEntityInstances"
      method: "POST"
      dataType: "json"
      data:
        orgUnit: options.organisationUnit
        trackedEntity: @malariaCaseEntityId
      error: (error) -> console.log error
      success: (result) ->
        options.success(result.reference)

  enrollTrackedEntityInstanceInProgram: (options) =>
    @request
      api: "enrollments"
      method: "POST"
      dataType: "json"
      data:
        trackedEntityInstance: options.trackedEntityInstanceId
        program: @programId
        orgUnit: options.organisationUnit
        attributes: [
          {attribute: @ageAttributeId, value: options.age}
          {attribute: @caseIdAttributeId, value: options.caseId}
        ]
      error: (error) -> console.log error
      success: (result) -> options.success(result)

  updateTrackedEntityInstance: (options) ->
    @request
      api: "trackedEntityInstances"
      type: "post"
      dataType: "json"
      data:
        orgUnit: options.organisationUnit
        trackedEntity: @malariaCaseEntityId
        attributes: [
          {attribute: @ageAttributeId, value: options.age}
          {attribute: @caseIdAttributeId, value: options.caseId}
        ]
      error: (error) -> console.log error
      success: (result) ->
        console.log result
        options.success(result)
    #TODO


  createOrUpdateMalariaCase: (malariaCase) =>
    organisationUnit = "pFMOFIccnPf" # TODO actually look this up
    malariaCaseId = malariaCase.caseId()
    @trackedEntityInstanceIdForCaseId
      organisationUnit: organisationUnit
      caseId: malariaCaseId
      error: (error) -> console.error error
      success: (trackedEntityInstanceId) =>
        if trackedEntityInstanceId
          @updateTrackedEntityInstance
            trackedEntityInstanceId: trackedEntityInstanceId
            age: malariaCase.ageInYears()
            caseId: malariaCaseId.caseId()
        else
          @createTrackedEntityInstance
            organisationUnit: organisationUnit
            error: (error) -> console.error error
            success: (trackedEntityInstanceId) =>
              @enrollTrackedEntityInstanceInProgram
                trackedEntityInstanceId: trackedEntityInstanceId
                organisationUnit: organisationUnit
                age: malariaCase.ageInYears()
                caseId: malariaCase.caseId()


module.exports = Dhis2
