#
# Copyright (C) 2015 by Looker Data Services, Inc.
# All rights reserved.
#

angular = require 'angular'
{EVENT} = require '../../../constants'

############################################################################################################

angular.module('work').factory 'WorkEditorActions', (reflux)->
    reflux.createActions
        beginEditing: { children: ['success', 'error'] }
        cancel: {}
        save: { children: ['success', 'error']}

############################################################################################################

angular.module('work').factory 'WorkEditorStore', (reflux, Work, WorkEditorActions)->
    reflux.createStore
        init: ->
            @_editing   = false
            @_error     = null
            @_workModel = null
            @_workView  = null

            @listenToMany WorkEditorActions

        get: ->
            return @_workView

        getError: ->
            return @_error

        isEditing: ->
            return @_isEditing

        onBeginEditing: (id)->
            return unless id?
            console.log "WorkEditorStore.onBeginEditing(#{id})"

            @_isEditing = false
            Work.find id
                .then (model)->
                    WorkEditorActions.beginEditing.success id, model
                .catch (error)->
                    WorkEditorActions.beginEditing.error id, error

        onBeginEditingSuccess: (id, model)->
            console.log "WorkEditorStore.onBeginEditingSuccess(#{id}, #{JSON.stringify(model.toView())})"
            @_error     = null
            @_isEditing = true
            @_workModel = model
            @_workView  = model.toView()

            @trigger EVENT.ERROR, id, null
            @trigger EVENT.CHANGE, id, @_workView

        onBeginEditingError: (id, error)->
            console.log "WorkEditorStore.onBeginEditingError(#{id}, #{error})"
            @_error = error

            @trigger EVENT.ERROR, id, error
            @trigger EVENT.DONE

        onCancel: ->
            return unless @isEditing()
            console.log "WorkEditorStore.onCancel()"
            @_isEditing = false

            @trigger EVENT.CHANGE, @_workView.id, @_workView
            @trigger EVENT.DONE

        onSave: ->
            return unless @isEditing()
            console.log "WorkEditorStore.onSave()"

            @_workModel.mergeView @_workView
            @_workModel.DSSave()
                .then =>
                    WorkEditorActions.save.success @_workView.id, @_workView
                .catch (error)=>
                    WorkEditorActions.save.error @_workView.id, error

        onSaveSuccess: (id, view)->
            console.log "WorkEditorStore.onSaveSuccess(#{id}, #{JSON.stringify(view)})"
            @_error     = null
            @_isEditing = false

            @trigger EVENT.ERROR, id, null
            @trigger EVENT.SAVE, id, view
            @trigger EVENT.DONE, id, view

        onSaveError: (id, error)->
            console.log "WorkEditorStore.onSaveError(#{id}, #{JSON.stringify(error)})"
            @_error = error

            @trigger EVENT.ERROR, id, error
            @trigger EVENT.DONE, id, null
