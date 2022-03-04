include <BOSL/constants.scad>
include <NopSCADlib/lib.scad>
use <BOSL/metric_screws.scad>
use <BOSL/shapes.scad>
use <BOSL/transforms.scad>

// Epsilon value for offsetting coincident face differences.
E = 0.004;

case_width = 41;
case_length = 75;
case_height = 22;

wall_thickness = 3;
corner_radius = 3;
corner_extension_thickness = wall_thickness * 2;

lid_thickness = 3;
lid_screw_hole_diameter = 3.8;

threaded_insert_hole_diameter = 4.4;
threaded_insert_hole_depth = 7;

usb_screw_hole_diameter = 3.8;

usb_port_hole_height = 8;
usb_port_hole_width = 15;

gcc_connector_diameter = 14;
gcc_connector_length = 28.8;
gcc_connector_centre_to_flat_side = 5;
gcc_connector_slot_clearance = 0.25;
gcc_connector_slot_thickness = 3;
gcc_connector_slot_length = 25;

gcc_connector_stopper_thickness = 5;
gcc_connector_stopper_reinforcement_angle = 55;
gcc_connector_stopper_gap_size = 5;
gcc_connector_stopper_corner_radius = 1;

pcb_width = 34;
pcb_length = 34;
pcb_centre_x = 0;
pcb_centre_y = -8.75;
pcb_standoff_x_inset = 4;
pcb_standoff_y_inset = 4;
pcb_screw_hole_x = (
  pcb_centre_x
  + (pcb_width / 2)
  - pcb_standoff_x_inset
);
pcb_screw_hole_y = (
  pcb_centre_y
  + (pcb_length / 2)
  - pcb_standoff_y_inset
);

pcb_standoff_height = 2.5;
pcb_standoff_diameter = 2.6;
pcb_standoff_wall_thickness = 1.5;

/* Begin modules */ 
case();
*lid();
pcb_preview();


module case() {
  difference() {
    case_with_corner_extensions();

    // Move to the near end of the case and cut out USB panel mount holes.
    translate([0, -case_length / 2 - E, 0]) {
      usb_panel_mount();
    }

    // Move to the far end of the case and cut out GCC connector hole.
    translate([0, case_length / 2 + E, 0]) {
      gcc_connector_hole();
    }

    // Cut holes for threaded inserts in the centre of the squares created by
    // the outer and inner corner pieces.
    threaded_insert_holes();
  }

  // Move to the far end of the case and create GCC connector slot.
  translate([0, case_length / 2 + E, 0]) {
    gcc_connector_slot();
  }

  // Create standoffs for the Raspberry Pi Pico.
  pcb_standoffs();
}

module case_with_corner_extensions() {
  difference() {
    // Base shape.
    cuboid([
      case_width,
      case_length,
      case_height,
    ], fillet=corner_radius, edges=EDGES_Z_ALL);

    // Hollow out the cuboid.
    translate([0, 0, wall_thickness])
      cuboid([
        case_width - wall_thickness * 2,
        case_length - wall_thickness * 2,
        case_height,
      ]);
  }

  // Extend corners inwards.
  corner_extensions();
}

module usb_panel_mount() {
  // USB port hole.
  cuboid([
    usb_port_hole_width,
    wall_thickness * 2 + 1,
    usb_port_hole_height,
  ]);
}

module gcc_connector_hole() {
  // Create hole in wall for GCC connector.
  difference() {
    ycyl(
      l=wall_thickness + E * 2,
      d=gcc_connector_diameter + gcc_connector_slot_clearance * 2,
      align=V_FWD,
    );

    translate([
      0,
      0,
      -(gcc_connector_centre_to_flat_side + gcc_connector_slot_clearance),
    ])
      cuboid([
        gcc_connector_diameter,
        wall_thickness + E * 2,
        gcc_connector_slot_thickness,
      ], align=V_DOWN + V_FWD);
  }
}

module gcc_connector_slot() {
  // We again create the interior slot shape but this time in 2D. We then create
  // a shell around this 2D slot shape, and linear extrude it for the length of
  // the slot to create the final 3D exterior slot shape.
  rotate([90])
    linear_extrude(gcc_connector_slot_length) 
      shell2d(gcc_connector_slot_thickness)
        // This circle and square are equivalent to the ycyl and cuboid in
        // gcc_connector_hole().
        difference() {
          circle(d=gcc_connector_diameter + gcc_connector_slot_clearance * 2);
          translate([
            0,
            -(gcc_connector_centre_to_flat_side
              + gcc_connector_slot_clearance
              + gcc_connector_slot_thickness / 2)
          ])
            square([
              gcc_connector_diameter,
              gcc_connector_slot_thickness,
            ], center=true);
          }
}

module corner_extensions() {
  // Inner corner blocks for threaded inserts to go into.
  yflip_copy() xflip_copy() translate([
    case_width / 2 - wall_thickness,
    case_length / 2 - wall_thickness,
    case_height / 2,
  ])
    // Corner extension thing.
    cuboid(
      [
        corner_extension_thickness,
        corner_extension_thickness,
        case_height - wall_thickness,
      ],
      fillet=corner_radius,
      edges=EDGE_FR_LF,
      align=V_DOWN + V_FWD + V_LEFT,
    );
}

module threaded_insert_holes() {
  // Place hole for threaded insert at centre point of extended inner corners.
  yflip_copy() xflip_copy() translate([
    (case_width - wall_thickness - corner_extension_thickness) / 2,
    (case_length - wall_thickness - corner_extension_thickness) / 2,
    case_height / 2 + E,
  ])
    zcyl(
      d=threaded_insert_hole_diameter,
      l=threaded_insert_hole_depth + E,
      align=V_DOWN,
    );
}

module pcb_standoffs() {
  yflip_copy(cp=[0, pcb_centre_y]) xflip_copy(cp=[pcb_centre_x, 0])
    translate([
      pcb_screw_hole_x,
      pcb_screw_hole_y,
      -case_height / 2 + wall_thickness,
    ])
      linear_extrude(pcb_standoff_height)
        shell2d(pcb_standoff_wall_thickness)
          circle(d=pcb_standoff_diameter);
}

module lid() {
  lid_z_offset = case_height / 2;

  translate([0, 0, lid_z_offset]) {
    difference() {
      cuboid(
        [case_width, case_length, lid_thickness],
        fillet=corner_radius,
        edges=EDGES_Z_ALL,
        align=V_UP,
      );

      // Cut out screw holes in the lid.
      lid_screw_holes();
    }

    // Slot thing that holds GCC connector in place.
    gcc_connector_stopper();
  }
}

module lid_screw_holes() {
  // Place lid screw hole in same place as threaded insert hole.
  yflip_copy() xflip_copy() translate([
    (case_width - wall_thickness - corner_extension_thickness) / 2,
    (case_length - wall_thickness - corner_extension_thickness) / 2,
    lid_thickness + E,
  ])
    metric_bolt(
      size=lid_screw_hole_diameter,
      l=6,
      headtype="countersunk",
      pitch=0,
      align=V_DOWN,
    );
}

module gcc_connector_stopper() {
  gcc_connector_stopper_height = (
    case_height
    - wall_thickness
    - pcb_standoff_height
    - 2.5
  );

  gcc_connector_stopper_reinforcement_length = (
    pow(tan(gcc_connector_stopper_reinforcement_angle), -1)
    * gcc_connector_stopper_height
  );
  
  // Move to position for stopper.
  translate([
    0,
    (
      case_length / 2
      - gcc_connector_length - 0.5
      - gcc_connector_stopper_thickness / 2
    ),
    0,
  ])
    difference() {
      // The stopper itself.
      hull() {
        cuboid([
          gcc_connector_diameter,
          gcc_connector_stopper_thickness,
          gcc_connector_stopper_height
        ], align=V_DOWN, fillet=1, edges=EDGES_Y_BOT);

        xflip_copy() translate([
          -(gcc_connector_diameter / 2 - gcc_connector_stopper_corner_radius),
          -(
            gcc_connector_stopper_thickness / 2
            + gcc_connector_stopper_reinforcement_length
          ),
          0,
        ])
          cylinder(r=gcc_connector_stopper_corner_radius, h=E);
    }

    // Slot/gap for cable/wires coming out of GCC connector.
    hull() {
      translate([0, 0, -case_height / 2])
        ycyl(
          d=gcc_connector_stopper_gap_size,
          l=(
            gcc_connector_stopper_thickness
            + gcc_connector_stopper_reinforcement_length
            + E
          )
        );
      translate([0, 0, -gcc_connector_stopper_height])
        cuboid([
          gcc_connector_stopper_gap_size,
          (
            gcc_connector_stopper_thickness
            + gcc_connector_stopper_reinforcement_length
            + E
          ),
          E
        ], align=V_UP);
    }
  }
}

module pcb_preview() {
  translate([
    pcb_centre_x - 0.22,
    pcb_centre_y + 3,
    -case_height / 2 + wall_thickness + pcb_standoff_height,
  ]) {
    color("green") import("GameKeeb-PCB.stl");

    translate([0.22, -24, -1.5]) rotate([90, 0, 0])
      import("USB-A-Port.stl");
  }
}
