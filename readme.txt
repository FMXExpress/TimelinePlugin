TTimeLine
FMXExpress.com
http://www.fmxexpress.com/

If you have ever used any kind of animation software (like Adobe Flash Pro) you are 
familiar with the concept of a timeline. Delphi XE7 Firemonkey doesn't really have 
that concept of a timeline. I thought it would be interesting to introduce that 
concept of a timeline IDE tool and component to Delphi XE7. A timeline can greatly 
speed up rapid application development especially for mobile applications and make 
it easier for novice developers to produce apps quickly. I used a number of different 
developers on oDesk to come up with a TTimeLine component and IDE dialog window 
prototype. It probably cost around $500-$1000 via oDesk to get the prototype to 
where it is now based on the architecture that I wanted. The prototype does utilize 
TFiremonkeyContainer by developer David Millington to allow for a Firemonkey form 
within the Delphi IDE. The basic functionality is a timeline interface where you 
can add layers of components and then you can add multiple frames to each layer. 
The TTimeLine component manages the visibility of the components based on the current 
frame. It supports simple navigation of the timeline with functions like TTimeLine.Play, 
TTimeLine.Stop, TTimeLine.Next, TTimeLine.Prev, TTimeLine.GotoAndPlay, and 
TTimeLine.GotoAndStop. There is a demo application included within the download 
which demonstrates how the timeline can be used to create an animation of a circle 
bouncing in 5 easy frames.