import fn from './imports/client/notice.js'
import { NoticeManager } from 'meteor/simply:notices'

NoticeManager.provide('updates', fn)
