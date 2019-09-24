/*
 * Copyright (c) 2017-2019 José Amuedo (https://github.com/spheras)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace DesktopFolder.UtilGtkAnimation  {
    /**
     * @name AnimateFn
     * @description Animate Function to be executed en each frame
     * @param {double} ellapsed the time ellapsed since the start of the animation
     */
    protected delegate void AnimateFn (double ellapsed);

    public void animate_move (Gtk.Widget widget, Gdk.Point to, double duration, UtilFx.AnimationMode mode = UtilFx.AnimationMode.EASE_OUT_BACK) {
        WidgetAnimationMove animation = new WidgetAnimationMove (widget, to, duration, mode);
        animation.start ();
    }

    /**
     * @class
     * @name WidgetAnimation
     * @description util abstract class to animate widgets, each implementation should implement the animation itself
     */
    public abstract class WidgetAnimation {
        /** the time when the animation was started, in ms */
        protected double _start_time;
        /** the duration of the animation, ms */
        protected double _duration;
        /** the widget to be moved */
        protected Gtk.Widget _widget;
        /** the animation function to be executed in each frame */
        protected unowned AnimateFn _animation_fn;
        /** the uid reference for the animation */
        private uint _animation_ref;

        /**
         * @constructor
         * @param {Gtk.Widget} widget the widget to animate
         * @param {double} duration the duration of the animation
         * @param {AnimateFn} animation_fn the animation function
         */
        protected WidgetAnimation (Gtk.Widget widget, double duration, AnimateFn animation_fn) {
            this._widget       = widget;
            this._animation_fn = animation_fn;
            this._duration     = duration;
        }

        /**
         * @name get_pending_animations
         * @description return the pending animations for this animation
         * @return {List<WidgetAnimation>} the list of widget animations that are pending
         */
        protected abstract unowned Gee.List <WidgetAnimation> get_pending_animations ();

        /**
         * @name find_pending_animations
         * @description util method to find a pending animation for the widget
         * @return {WidgetAnimation} the Widget animation found or null
         */
        private WidgetAnimation ? find_pending_animations () {
            unowned Gee.List <WidgetAnimation> pending_animations = this.get_pending_animations ();
            for (var i = 0; i < pending_animations.size; i++) {
                WidgetAnimation anim = pending_animations.@get (i);
                if (anim.get_widget () != null && anim.get_widget () == this._widget) {
                    return anim;
                }
            }
            return null;
        }

        /**
         * @name finish_pending_animations
         * @description finish all pending animations for the widget
         */
        private void finish_pending_animations () {
            WidgetAnimation found = this.find_pending_animations ();
            if (found != null) {
                found.stop ();
            }
            unowned Gee.List <WidgetAnimation> pending_animations = this.get_pending_animations ();
            pending_animations.remove (found);
        }

        /**
         * @name stop
         * @description stop the current animation, simulating the last frame
         */
        public void stop () {
            // removing the pending threads
            try {
                Source.remove (this._animation_ref);
            } catch (Error err) {

            }
            // executing the last frame
            // this._animation_fn (this._duration);
        }

        /**
         * @name start
         * @description start the animation
         */
        public void start () {
            // first we finish all the pending animations for the widget
            this.finish_pending_animations ();

            // adding a new pending animation
            unowned Gee.List <WidgetAnimation> pending_animations = this.get_pending_animations ();
            pending_animations.add (this);

            // and starting a new one
            this._start_time    = (double) GLib.get_real_time () / 1000;
            this._animation_ref = GLib.Timeout.add (40, () => {
                double current = (double) GLib.get_real_time () / 1000;
                double ellapsed = current - this._start_time;
                this._animation_fn (ellapsed);
                if (ellapsed < this._duration) {
                    return true;
                } else {
                    WidgetAnimation found = this.find_pending_animations ();
                    pending_animations.remove (found);
                    return false;
                }
            });
        }

        /**
         * @Getter
         */
        public Gtk.Widget ? get_widget () {
            return this._widget;
        }

        /**
         * @Getter
         */
        public double get_duration () {
            return this._duration;
        }

    }

    /**
     * @name WidgetAnimationMove
     * @description util class to move a Gtk.Widget from its current place to a different place
     */
    public class WidgetAnimationMove : WidgetAnimation   {
        /** list of pending move animations */
        private static Gee.List <WidgetAnimation> move_animations = null;

        static construct {
            WidgetAnimationMove.move_animations = new Gee.ArrayList <WidgetAnimation>();
        }

        /**
         * @override
         */
        protected override unowned Gee.List <WidgetAnimation> get_pending_animations () {
            // WidgetAnimationMove.move_animations.append(this);
            return WidgetAnimationMove.move_animations;
        }

        /**
         * @constructor
         * @param {Gtk.Widget} widget the widget to animate
         * @param {Gdk.Point} to the point x,y where the widget will be placed at the end of the animation
         * @param {double} duration the duration of the animation
         * @param {UtilFx.AnimationMode} mode (optional) the animation to perform @see UtilFx.AnimationMode, by default EASE_OUT_BACK
         */
        public WidgetAnimationMove (Gtk.Widget ? widget, Gdk.Point ? to, double ? duration, UtilFx.AnimationMode mode = UtilFx.AnimationMode.EASE_OUT_BACK) {
            // calculating the distances and positions to animate
            Gtk.Fixed      parent = (Gtk.Fixed)widget.get_parent ();
            Gtk.Allocation widget_alloc;
            widget.get_allocation (out widget_alloc);
            int x           = widget_alloc.x;
            int y           = widget_alloc.y;
            int x_dist      = to.x - x;
            int y_dist      = to.y - y;
            int x_dist_curr = 0;
            int y_dist_curr = 0;

            // the animation function
            AnimateFn anim_fn = (ellapsed) => {
                if (ellapsed < duration) {
                    double ease = UtilFx.easing_for_mode (mode, ellapsed, duration);
                    x_dist_curr = (int) (x_dist * ease);
                    y_dist_curr = (int) (y_dist * ease);
                    parent.move (widget, x + x_dist_curr, y + y_dist_curr);
                } else {
                    // last frame
                    parent.move (widget, to.x, to.y);
                }
            };

            base (widget, duration, (ell) => {
                // trick to allow access to widget!
                // help: why widget is null inside this closure when called from the Glib.Timeout.add??
                anim_fn (ell);
            });
        }

    }

}
