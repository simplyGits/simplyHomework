#!/usr/bin/env node
var util=require("util");

REQ=require("./planner")
H=REQ.HomeworkDescription
P=REQ.Planner
function hh(s,l){var h=new H;h.subject=s;h.location=l;return h;}
function inspect(o){console.log(util.inspect(o,{depth:8}));}
function startOfDay(date){return new Date(date.getFullYear(),date.getMonth(),date.getDate());}
function addDays(date,ndays){return new Date(date.getTime()+ndays*24*3600*1000);}
p=new P
p.learn(hh("ne",[[1,1],[1,2]]),100)
p.learn(hh("ne",[[1,5]]),40)
inspect(p.persistable())
p.estimate(hh("ne",[[1,5]]))
p.estimate(hh("ne",[[1,4]]))
var schedule=p.plan([H("ne",[[1,2]],addDays(startOfDay(new Date),2)),H("ne",[[1,1],[1,5]],addDays(startOfDay(new Date),1))],[1,1],new Date)
console.log(schedule)
