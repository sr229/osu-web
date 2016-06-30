###
# Copyright 2015 ppy Pty. Ltd.
#
# This file is part of osu!web. osu!web is distributed with the hope of
# attracting more community contributions to the core ecosystem of osu!.
#
# osu!web is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License version 3
# as published by the Free Software Foundation.
#
# osu!web is distributed WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with osu!web.  If not, see <http://www.gnu.org/licenses/>.
###

landingGraphWrapper = document.getElementsByClassName('js-landing-graph')
landingGraphInit = document.getElementsByClassName('js-landing-graph-initialized')

if landingGraphWrapper[0]?
  if !landingGraphInit[0]?
    # Define margins
    margin = 
      top: 40
      right: 0
      bottom: 0
      left: 0
    width = parseInt(d3.select('.js-landing-graph').style('width')) - (margin.left) - (margin.right)
    height = parseInt(d3.select('.js-landing-graph').style('height')) - (margin.top) - (margin.bottom)
    # Define peak circle
    peakR = 5
    # Define date parser
    parseDate = d3.time.format('%Y-%m-%d %H:%M:%S').parse
    xScale = d3.time.scale().range([
      0
      width
    ])
    yScale = d3.scale.linear().range([
      height
      0
    ])
    # Peak text indicator point
    maxElem = null
    # Define area
    area = d3.svg.area().interpolate('basis')
      .x (d) ->
        xScale d.date
      .y0(height).y1 (d) ->
        yScale d.users_osu
    # Define the graph
    svg = null
    textLength = 0

    modelStats = (data) ->
      # Define svg canvas
      svg = d3.select '.js-landing-graph'
        .append 'svg'
        .attr 'width', width + margin.left + margin.right
        .attr 'height', height + margin.top + margin.bottom
        .attr 'class', 'js-landing-graph-initialized'
        .append 'g'
        .attr 'transform', 'translate(' + margin.left + ',' + margin.top + ')'

      # Parsing data
      data.forEach (d) ->
        d.date = parseDate(d.date)
        d.users_osu = +d.users_osu

      # Establishing domain for x/y axes
      xScale.domain d3.extent(data, (d) ->
        d.date
      )
      yScale.domain [
        0
        d3.max(data, (d) ->
          d.users_osu
        )
      ]
      # Remove any existing paths
      svg.selectAll 'path'
        .remove

      # Appending groups
      svg.append 'path'
        .datum data
        .attr 'class', 'landing-graph__area'
        .attr 'd', area

      #Find the date for the max, from the end backward
      i = data.length - 1
      while i >= 0
        if maxElem == null or data[i].users_osu > maxElem.users_osu
          maxElem = data[i]
        i--

      text = svg.append 'text' 
        .attr 'class', 'landing-graph__text'
        .text Lang.get('home.landing.peak', 'count': maxElem.users_osu.toLocaleString())
        .attr 'y', -peakR * 2

      # Get the width of the element to determine angle offset
      rightX = xScale(maxElem.date) + peakR * 2
      textLength = text.node().getComputedTextLength()
      if (textLength + rightX) > width
        text.attr 'x', xScale(maxElem.date) - textLength - peakR * 2
      else
        text.attr 'x', rightX

      peak = svg.append 'circle'
        .attr 'class', 'landing-graph__circle'
        .attr 'cy', 0
        .attr 'cx', xScale(maxElem.date)
        .attr 'r', peakR

    # Load the data
    stats = osu.parseJson('json-stats')
    modelStats stats

  landingResize = ->
    width = parseInt(d3.select('.js-landing-graph').style('width')) - (margin.left) - (margin.right)
    height = parseInt(d3.select('.js-landing-graph').style('height')) - (margin.top) - (margin.bottom)
    d3.select '.js-landing-graph svg'
      .attr 'width', width + margin.left + margin.right
      .attr 'height', height + margin.top + margin.bottom
    # Update the range of the scale with new width/height
    xScale.range [
      0
      width
    ]
    yScale.range [
      height
      0
    ]
    # Force D3 to recalculate and update the line
    svg.selectAll('path').attr 'd', area

    rightX = xScale(maxElem.date) + peakR * 2
    if (textLength + rightX) > width
      svg.select('.landing-graph__text').attr 'x', xScale(maxElem.date) - textLength - peakR * 2
    else
      svg.select('.landing-graph__text').attr 'x', rightX
      
    svg.select('.landing-graph__circle').attr 'cx', xScale(maxElem.date)

$(window).on 'resize', ->
  if landingGraphWrapper[0]?
    landingResize()
