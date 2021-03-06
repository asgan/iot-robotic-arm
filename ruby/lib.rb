module Rucicka
  module Lib
    MIN_ELBOW = 19
    MIN_SHOULDER = 50
    MIN_WRIST = 0
    MIN_BASE = 40
    MIN_GRIPPER = 30
    MIN_WRIST_ROTATE = 0

    MAX_ELBOW = 90
    MAX_SHOULDER = 170
    MAX_WRIST = 180
    MAX_BASE = 120
    MAX_GRIPPER = 110
    MAX_WRIST_ROTATE = 86

    WAIT_INTERVAL = 0.15
    STEP_INTERVAL = 0.022

    GRIPPER_LENGTH = 1.1 #cm

    def position_to_coords(rotation, height, distance, gripper, wrist_rotate, wrist = nil)
      wrist ||= 90
      gripper_adjustment = gripper_adjustment(distance, height, wrist)
      h = height
      h += gripper_adjustment unless gripper_adjustment.nil?
      x = Math.sqrt((distance ** 2) + (h ** 2))
      p "rot:#{rotation}, height:#{h}, dist: #{distance}, wrist: #{wrist}"
      if x >= (M + N) || gripper_adjustment.nil?
        # puts 'rucicka> Desired position is unreachable!'
        return
      end

      s = 0.5 * (M + N + x)
      elbow = compute_angle(s, M, N).degrees
      small_shoulder = compute_angle(s, M, x).degrees
      big_shoulder = Math.asin(h / x.to_f).degrees

      shoulder = small_shoulder + big_shoulder

      unless ENV['DEBUG'].nil?
        p "X = #{x} cm"
        p "S = #{s} cm2"
        p "small_shoulder = #{small_shoulder} deg"
        p "big_shoulder = #{big_shoulder} deg"
        p "shoulder = #{shoulder} deg"
        p "elbow = #{elbow} deg"
        p "wrist = #{wrist} deg"
      end

      # calibration correction
      shoulder += 20
      elbow -= 5

      input = "#{elbow},#{shoulder},#{wrist},#{rotation},#{gripper},#{wrist_rotate}"

      constrain(coords_parse(input))
    end

    def gripper_adjustment(distance, height, wrist)
      x = Math.sqrt((distance ** 2) + (height ** 2))
      if x >= (M + N)
        return
      end

      s = 0.5 * (M + N + x)

      gamma = compute_angle(s, x, N).degrees
      epsilon = Math.asin(distance / x.to_f).degrees
      alpha = 360 - (wrist + 90)
      tau = alpha - gamma - epsilon
      a = (Math.cos(tau.radians) * GRIPPER_LENGTH)
      a = tau > 90 ? 0 : a.abs
      a = tau <= 0 ? GRIPPER_LENGTH : a.abs
      unless ENV['DEBUG'].nil?
        p "X = #{x} cm"
        p "S = #{s} cm2"
        p "alpha = #{alpha}°"
        p "gamma = #{gamma}°"
        p "epsilon = #{epsilon}°"
        p "cos(tau) = #{Math.cos(tau)}°"
        puts "Adjustment: \n tau: #{tau}° \n adjust: #{a}cm"
      end
      a
    end

    def coords_parse(payload)
      values = payload.split(',')
      coords = {}

      coords[:elbow] = values[0].to_i
      coords[:shoulder] = values[1].to_i
      coords[:wrist] = values[2].to_i
      coords[:base] = values[3].to_i
      coords[:gripper] = values[4].to_i
      coords[:wrist_rotate] = values[5].to_i

      coords
    end

    def coords_format(coords)
      "#{coords[:elbow]},#{coords[:shoulder]},#{coords[:wrist]},#{coords[:base]},#{coords[:gripper]},#{coords[:wrist_rotate]}"
    end

    def compute_angle(s, k, l)
      Math.asin(Math.sqrt(((s - k) * (s - l)) / (k * l))) * 2
    end

    def constrain(coords)
      constrained = {}

      constrained[:elbow] = bound(coords[:elbow], MIN_ELBOW, MAX_ELBOW)
      constrained[:shoulder] = bound(coords[:shoulder], MIN_SHOULDER, MAX_SHOULDER)
      constrained[:wrist] = bound(coords[:wrist], MIN_WRIST, MAX_WRIST)
      constrained[:base] = bound(coords[:base], MIN_BASE, MAX_BASE)
      constrained[:gripper] = bound(coords[:gripper], MIN_GRIPPER, MAX_GRIPPER)
      constrained[:wrist_rotate] = bound(coords[:wrist_rotate], MIN_WRIST_ROTATE, MAX_WRIST_ROTATE)

      constrained
    end

    def bound(value, min, max)
      [[min, value].max, max].min
    end

    def mqtt_format(coords)
      "#{coords[:elbow]},#{coords[:shoulder]},#{coords[:wrist]},#{coords[:base]},#{coords[:gripper]},#{coords[:wrist_rotate]}"
    end

    def mqtt_parse(payload)
      values = payload.split(',')
      coords = {}

      coords[:elbow] = values[0].to_i
      coords[:shoulder] = values[1].to_i
      coords[:wrist] = values[2].to_i
      coords[:base] = values[3].to_i
      coords[:gripper] = values[4].to_i
      coords[:wrist_rotate] = values[5].to_i

      coords
    end

    def define_presents
      @presets = {}
      @presets[:default] = {
          elbow: 50,
          shoulder: 140,
          wrist: 90,
          base: 70,
          gripper: 40,
          wrist_rotate: 86
      }
      @presets[:low] = {
          elbow: 60,
          shoulder: 110,
          wrist: 120,
          base: 50,
          gripper: 30,
          wrist_rotate: 86
      }
      @presets[:high] = {
          elbow: 40,
          shoulder: 130,
          wrist: 30,
          base: 90,
          gripper: 90,
          wrist_rotate: 0
      }
      @presets[:park] = {
          elbow: 19,
          shoulder: 170,
          wrist: 80,
          base: 75,
          gripper: 40,
          wrist_rotate: 86
      }
      @presets[:ninety] = {
          elbow: 85,
          shoulder: 110,
          wrist: 90,
          base: 70,
          gripper: 40,
          wrist_rotate: 86
      }
      @presets[:max] = {
          elbow: MAX_ELBOW,
          shoulder: MAX_SHOULDER,
          wrist: MAX_WRIST,
          base: MAX_BASE,
          gripper: MAX_GRIPPER,
          wrist_rotate: MAX_WRIST_ROTATE
      }
      @presets[:min] = {
          elbow: MIN_ELBOW,
          shoulder: MIN_SHOULDER,
          wrist: MIN_WRIST,
          base: MIN_BASE,
          gripper: MIN_GRIPPER,
          wrist_rotate: MIN_WRIST_ROTATE
      }
    end
  end
end
