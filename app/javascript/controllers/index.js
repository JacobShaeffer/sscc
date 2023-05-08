// This file is auto-generated by ./bin/rails stimulus:manifest:update
// Run that command whenever you add a new controller or create them with
// ./bin/rails generate stimulus controllerName

import { application } from "./application"

import fileSelectController, {string_identifier as fileSelect_id} from "./fileSelect_controller"
application.register(fileSelect_id, fileSelectController)

import multiSelectController, {string_identifier as multiSelect_id} from "./multiSelect_controller"
application.register(multiSelect_id, multiSelectController)

import accordionController, {string_identifier as accordion_id} from "./accordion_controller"
application.register(accordion_id, accordionController)